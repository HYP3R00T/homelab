<p align="center">
  <img src="docs/assets/branding/banner.svg" alt="Homelab — private by design, versioned in Git" width="100%">
</p>

<p align="center">
  <a href="https://hyp3r00t.github.io/homelab/">Documentation</a> ·
  <a href="docs/architecture/index.md">Architecture</a> ·
  <a href="docs/setup/index.md">Setup guide</a> ·
  <a href="docs/runbooks/index.md">Runbooks</a>
</p>

# Homelab

A private, single-node Ubuntu K3s homelab, managed through Flux, Kustomize, and Helm. Built around a small VM—4 vCPUs and approximately 5.28 GiB RAM—with explicit ownership, dependency-aware reconciliation, and persistent data that has a recovery plan.

## The architecture

[![Full-system architecture: GitOps, private LAN access, applications, secrets, monitoring, and local storage](docs/assets/diagrams/architecture.svg)](docs/assets/diagrams/architecture.svg)

[Open the architecture diagram at full size](docs/assets/diagrams/architecture.svg).

The diagram describes the **declared configuration**, not live availability. Homepage and Linkding reconcile independently. Monitoring waits for Vault authentication and credential delivery. Postiz, CloudNativePG, and Cloudflared are retained but inactive.

## What this project demonstrates

| Area | Engineering choice | Explore |
| --- | --- | --- |
| GitOps | One environment, individual resource files, and explicit readiness boundaries instead of duplicated overlays | [Reconciliation](docs/gitops/reconciliation.md) |
| Platform | K3s owns its packaged ingress, load balancing, DNS, storage, and live metrics; Flux does not install duplicates | [Platform](docs/architecture/platform.md) |
| Secrets | Public references in Git, private values in Vault, Terraform-managed authentication, and ESO delivery | [Secret flow](docs/architecture/secrets-flow.md) |
| Observability | Homepage for current readings; Prometheus and Grafana for history and per-workload assessment | [Monitoring](docs/infrastructure/kube-prometheus-stack.md) |
| Persistence | Retained volumes for new Vault/monitoring data, with explicit limits and recovery responsibilities | [Storage recovery](docs/runbooks/storage-recovery.md) |
| Access | Private LAN ingress and workstation hostname mappings, without a public tunnel or LAN DNS server | [Local access](docs/setup/local-access.md) |

## Inside the cluster

**Applications** are the tools people use: [Homepage](docs/apps/homepage.md) and [Linkding](docs/apps/linkding.md). **Infrastructure** supports and administers them: Flux, Vault, External Secrets, and monitoring, alongside K3s-packaged components. A web interface does not change that boundary.

![Homepage service cards showing applications and administrative interfaces](docs/assets/images/homepage.jpg)

*Homepage at capture time: application and Flux checks respond; Vault and monitoring checks show unfinished bootstrap. These indicators describe that moment, not a permanent service status.*

![Flux Status interface showing the source and controller overview](docs/assets/images/flux-status.jpg)

*Point-in-time Flux UI capture. Controller status complements individual reconciliation and secret-readiness checks; it is not proof that every application has completed bootstrap.*

## Reproduce and operate it

Start with the [ordered setup guide](docs/setup/index.md). It covers the workstation and K3s baseline, Flux bootstrap, hosts-file access, application initialization, and the Vault/monitoring chain. Installing a pod is only one stage: Linkding needs an owner account on a fresh installation, and Vault needs initialization, unsealing, authentication configuration, and secret values.

| Location | Responsibility |
| --- | --- |
| `gitops/apps/<component>/` | End-user application manifests and configuration |
| `gitops/infrastructure/<component>/` | Administrative and shared capabilities, including monitoring |
| `gitops/clusters/lab/` | Flux entrypoint and readiness dependencies |
| `iac/vault/` | Vault authentication, KV mount, policies, and role |
| `docs/` | Architecture, setup, component reference, and operations |

Flux watches `main`; pushing a feature branch does not deploy it. The manifests are the source of declared state. Use the [rollout checks](docs/runbooks/gitops-rollout.md) to verify the live cluster.

## Keep it maintainable

Each Kubernetes object has its own named YAML file. Removed deployment experiments live in Git history rather than an archive tree. New components belong to Applications or Infrastructure and gain a separate Flux group only when they need an independent lifecycle or readiness boundary.

Architecture assets have editable JSON sources and a dependency-free Python renderer:

```shell
python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py
python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py --check
```

The repository's `update-architecture-diagram` skill can inspect structural changes and update those sources and assets when explicitly invoked. It does not deploy resources. See the [architecture guide](docs/architecture/index.md) and [component workflow](docs/gitops/adding-a-service.md).

Local persistence is not a backup. Retain does not protect against host disk loss or K3s uninstall, and Linkding's existing volume retains its original policy. Secret values, unseal shares, Terraform state, and application data stay outside this public repository.
