---
icon: lucide/house
---

# A small cluster, deliberately built

<div class="hero" markdown>

![Homelab: self-hosted Kubernetes and GitOps automation](assets/branding/banner.svg){ .hero-art }

<div class="tech-badges" markdown>

[![Kubernetes / K3s](https://img.shields.io/badge/Kubernetes_K3s-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](architecture/platform.md)
[![GitOps / Flux CD](https://img.shields.io/badge/GitOps_Flux_CD-5468FF?style=flat-square&logo=flux&logoColor=white)](gitops/reconciliation.md)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white)](gitops/repository-structure.md)
[![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat-square&logo=terraform&logoColor=white)](architecture/secrets-flow.md)
[![Vault](https://img.shields.io/badge/Vault-B59A1F?style=flat-square&logo=vault&logoColor=white)](infrastructure/vault.md)

</div>

One Ubuntu VM. A K3s cluster. Applications and infrastructure kept in Git, with clear ownership and room to measure what each workload costs.

[Explore the architecture](architecture/index.md){ .md-button .md-button--primary } [Set up the homelab](setup/index.md){ .md-button }

</div>

## The whole system

[![Homelab architecture: GitOps, private LAN access, applications, secrets, and local storage](assets/diagrams/architecture.svg)](assets/diagrams/architecture.svg)

[Open the architecture diagram at full size](assets/diagrams/architecture.svg).

This is the **declared architecture**, not a live status board. Homepage and Linkding are included independently of Vault. Shoutrrr and CloudNativePG are included through dedicated groups; Shoutrrr waits for retained storage and Vault-backed credentials. Cloudflared publishes only Shoutrrr at `https://shoutrrr.hyperoot.dev`.

## Engineering choices

<div class="grid cards" markdown>

- :lucide-git-branch: **One source of configuration**

    Flux watches `main`. Kustomize assembles individual resource files, and Helm installs the shared components. [Follow reconciliation](gitops/reconciliation.md).

- :lucide-boxes: **One owner for each component**

    K3s supplies ingress, load balancing, DNS, local storage, and live metrics. Flux adds the applications and infrastructure without reinstalling those components. [See the platform boundary](architecture/platform.md).

- :lucide-key-round: **Secrets outside Git**

    Vault holds values, Terraform configures its authentication, and External Secrets delivers Kubernetes Secrets. Manual bootstrap is explicit. [Follow the secret path](architecture/secrets-flow.md).

- :lucide-chart-no-axes-combined: **Resources treated as a budget**

    The reference VM has 4 vCPUs and about 5.28 GiB RAM. Homepage and Metrics Server show current readings. Historical metrics and alerting are not installed. [Inspect current metrics](infrastructure/metrics-server.md).

</div>

## Applications

Applications are the tools used directly for everyday work. They have their own configuration, access, and data requirements.

<div class="grid cards" markdown>

- :lucide-layout-dashboard: **[Homepage](apps/homepage.md)**

    The personal starting page for application links, administrative interfaces, and current resource readings.

- :lucide-bookmark: **[Linkding](apps/linkding.md)**

    The private bookmark collection. A new installation needs an owner account before sign-in.

</div>

[Shoutrrr](apps/shoutrrr.md) is the social publishing trial, using one container, SQLite, and Vault-backed credentials. Inclusion does not imply a completed bootstrap. See the [application inventory](apps/index.md) for activation and setup details.

## Infrastructure

Infrastructure runs and administers the cluster. Some components have web interfaces, but those interfaces serve administration rather than changing the component's role.

<div class="grid cards" markdown>

- :lucide-git-branch: **[Flux](infrastructure/flux.md)**

    Reconciles the configuration in Git and exposes the operator's status interface.

- :lucide-key-round: **[Vault](infrastructure/vault.md) and [External Secrets](infrastructure/external-secrets.md)**

    Store private values and deliver Kubernetes Secrets. Vault initialization, unsealing, authentication, and credential population are separate setup steps.

- :lucide-server: **[K3s foundation](architecture/platform.md)**

    Supplies CoreDNS, Traefik, ServiceLB, local volume provisioning, and Metrics Server. These support components do not all need a dashboard shortcut.

</div>

The [infrastructure inventory](infrastructure/index.md) covers ownership, setup, CloudNativePG, and the Shoutrrr-only Cloudflared tunnel. Homepage's visible cards are shortcuts, not a complete list of cluster workloads.

## Find your route

| I want to… | Start here |
| --- | --- |
| Understand how everything fits | [Architecture](architecture/index.md) |
| See the end-user tools | [Applications](apps/index.md) |
| Inspect the administrative components | [Infrastructure](infrastructure/index.md) |
| Build a similar private cluster | [Setup](setup/index.md) |
| Change configuration safely | [GitOps](gitops/index.md) |
| Bootstrap, troubleshoot, or recover | [Runbooks](runbooks/index.md) |

The configuration is the evidence of intended behavior. Use the verification commands in each guide to establish what is actually running.
