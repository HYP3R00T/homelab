---
icon: lucide/folders
---

# Repository Structure

This repository is grouped by role. The goal is to keep it easy to understand what supports the platform, what users actually consume, and what observes the whole system.

## At a glance

```text
.
├── gitops/
│   ├── apps/              # User-facing workloads
│   ├── infrastructure/    # Platform services that support the cluster
│   ├── monitoring/        # Observability and inspection layer
│   └── clusters/          # Flux entrypoints that activate things in a cluster
└── iac/                   # OpenTofu/Terraform-style infrastructure as code
```

At the simplest level, `gitops/` contains the Kubernetes manifests Flux applies to the cluster, while `iac/` is reserved for infrastructure that will be managed outside the GitOps path. Inside `gitops/`, `apps/` is for things people use, `infrastructure/` is for the shared capabilities those apps need, `monitoring/` is for observing both layers, and `clusters/` is for deciding what actually goes live.

## File naming convention

Manifest filenames under `gitops/` use lowercase kebab-case. Name a file after
the Kubernetes resource kind when the component directory contains only one of
that kind:

- `service-account.yaml`
- `cluster-role-binding.yaml`
- `helm-repository.yaml`
- `persistent-volume-claim.yaml`

When a directory contains multiple resources of the same kind, prefix the kind
with the workload or purpose so each file is unambiguous:

- `grafana-external-secret.yaml`
- `prometheus-external-secret.yaml`
- `vault-service-monitor.yaml`
- `traefik-pod-monitor.yaml`

Keep the standard tool filenames `kustomization.yaml` and `values.yaml`.
Application configuration files such as Homepage's `services.yaml` retain the
names expected by that application. Do not introduce camelCase, snake_case, or
concatenated multiword Kubernetes kinds in new filenames.

## Apps

`gitops/apps/` is for services that are the actual destination.

These are the things a user opens, signs into, and actively uses. They are built on top of the shared capabilities provided by `gitops/infrastructure/`.

Examples:

- Homepage
- Linkding
- Mealie

!!! tip "Ask yourself"
    Is this something I or another person would actively use?
    If it disappeared, would a human notice before the platform noticed?
    Is this the destination rather than the plumbing?

If the answer is mostly yes, it belongs in `gitops/apps/`.

## Infrastructure

`gitops/infrastructure/` is for services that support the cluster or support other services.

This is the base layer that applications depend on. These services usually do not exist for their own sake. They exist so applications can receive traffic, use certificates, store secrets, reach databases, or be exposed externally when needed.

Examples:

- Traefik
- MetalLB
- Cloudflared
- Vault
- External Secrets Operator
- CloudNativePG

In this repository, infrastructure means shared capabilities such as:

- ingress and routing
- load balancing
- certificate management
- secret storage and secret delivery
- database services
- controlled external exposure

If multiple applications would rely on it as a common platform feature, it belongs in `gitops/infrastructure/`.

## Monitoring

`gitops/monitoring/` is for observability.

Monitoring is separate because it observes both `gitops/infrastructure/` and `gitops/apps/`. Its job is to tell us what is happening across the system, not to serve end users directly and not to provide platform capabilities.

Examples:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node exporters

If its primary job is to measure, record, alert, or explain what is happening in the system, it belongs in `gitops/monitoring/`.

Keep `gitops/monitoring/` as a separate top-level folder. It has a different responsibility from infrastructure: infrastructure enables workloads, while monitoring observes infrastructure and applications together.

Monitoring is split again by lifecycle:

- `monitoring/controllers/{base,lab}` installs the Prometheus Operator and
  bundled monitoring workloads, including resources required during startup.
- `monitoring/configs/{base,lab}` applies `PodMonitor`, `ServiceMonitor`, and
  supporting resources only after the controller CRDs are healthy.

## What `gitops/clusters/` does

`gitops/clusters/` is the activation layer.

This folder does not define the services themselves. It tells Flux which parts of the repository should be applied to a given cluster.

That means a manifest can exist in the repository without being live in the cluster yet.

!!! warning "Important distinction"
    A service can be present in the repo but absent from the cluster.
    The folder tells us what the service is for.
    The cluster wiring tells us whether it is currently active.

This is why commented entries in a `kustomization.yaml` matter so much. The files may exist, but the cluster will not reconcile them until the cluster wiring includes them.

For simple layers, a cluster entrypoint can target the whole overlay, such as
`./gitops/apps/lab`. Monitoring uses separate
`./gitops/monitoring/controllers/lab` and
`./gitops/monitoring/configs/lab` entrypoints so monitor custom resources are
not applied before their CRDs exist.

For infrastructure services that need stricter ordering, the cluster entrypoint can point directly at the environment overlays. In this repository, `gitops/clusters/lab/infrastructure-controllers.yaml` points to `gitops/infrastructure/controllers/lab`, and `gitops/clusters/lab/infrastructure-configs.yaml` points to `gitops/infrastructure/configs/lab`. The controller stage waits for the controller Helm releases to become healthy, and the config stage applies shared resources such as Vault, MetalLB config, External Secrets store config, and Cloudflared.

## Applying this to services in the repository

- `gitops/apps/`: `Homepage`, `Linkding`
- `gitops/infrastructure/`: `Traefik`, `MetalLB`, `Vault`, `External Secrets
  Operator`, `Cloudflared`, `Local Path Provisioner`, `NVIDIA GPU Operator`,
  `CloudNativePG`
- `gitops/monitoring/`: `Prometheus`, `Grafana`

CloudNativePG is installed as an operator, but no PostgreSQL `Cluster` resource
exists yet. The monitoring layer is active and applies its monitor resources
only after the Prometheus Operator CRDs are healthy.

## Working principle going forward

Before adding a new service, answer one question first: what role does this service play in the homelab?

If it is a shared capability, it belongs in `gitops/infrastructure/`.
If it is something people use directly, it belongs in `gitops/apps/`.
If it watches the whole system, it belongs in `gitops/monitoring/`.
