<div align="center">

# 🏡 homelab

## Talos Linux homelab managed with FluxCD, Kustomize, and Helm

[![Talos Linux](https://img.shields.io/badge/OS-Talos_Linux-0f62fe?style=for-the-badge&logo=linux&logoColor=white)](https://www.talos.dev/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Single_Node-326ce5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![FluxCD](https://img.shields.io/badge/GitOps-FluxCD-5468ff?style=for-the-badge&logo=flux&logoColor=white)](https://fluxcd.io/)
[![Docs](https://img.shields.io/badge/Docs-Zensical-0f766e?style=for-the-badge)](docs/)

A self-hosted Kubernetes lab built for clean GitOps workflows, shared platform services, and a small but intentional app layer.

</div>

> ⚙️ The repository is the source of truth for the cluster. Some services are active today, while others are staged here before they are reconciled.

## 🧰 Stack Overview

| Layer | Tooling |
|-------|---------|
| Kubernetes | [Talos Linux](https://www.talos.dev/) |
| GitOps | [FluxCD](https://fluxcd.io/) |
| Packaging | [Helm](https://helm.sh) + [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/) |
| Networking | [MetalLB](https://metallb.universe.tf/) + [Traefik](https://doc.traefik.io/traefik/) |
| Apps | Homepage + Linkding |
| Documentation | Zensical in `docs/` |

## 📁 Repository Structure

```text
.
├── gitops/                 # Flux-managed Kubernetes manifests
│   ├── apps/              # User-facing workloads
│   ├── infrastructure/    # Shared platform capabilities
│   ├── monitoring/        # Observability layer
│   └── clusters/          # Flux entrypoints for the lab cluster
├── iac/                   # OpenTofu/Terraform-style infrastructure as code
└── docs/                  # Documentation site
```

> ✅ `base/` holds reusable service definitions.
>
> 🧪 `lab/` holds homelab-specific overlays.
>
> 🎛️ `gitops/clusters/` decides what Flux actually reconciles.
>
> 🏗️ `iac/` is reserved for non-GitOps infrastructure configuration managed outside Kubernetes.

## 🚀 Current State

### Active now

| Layer | Active services |
|-------|-----------------|
| Apps | `homepage`, `linkding` |
| Infrastructure | `metallb`, `traefik`, `vault`, `external-secrets`, `cloudflared` |
| Monitoring | none enabled right now |

### Staged in the repository

- `cnpg`
- monitoring components

These exist in the repo because the design work is happening here first, but they are not all live in the cluster yet.

## 🧭 How It Flows

1. Manifests live in `gitops/apps/`, `gitops/infrastructure/`, and `gitops/monitoring/`.
2. `base/` defines the reusable service shape.
3. `lab/` adds homelab-specific values, ingress, storage, and overlays.
4. `gitops/clusters/lab/*.yaml` tells Flux what to reconcile and in what order.

## 📚 Documentation

- `docs/index.md` shows the current architecture
- `docs/architecture/` explains relationships that span multiple services
- `docs/gitops/` explains repository structure, reconciliation, and service wiring
- `docs/services/` documents individual services and dependencies
- `docs/runbooks/` contains repeatable setup, operations, and recovery procedures

## 🧠 Philosophy

- Keep the cluster declarative.
- Separate apps from shared infrastructure.
- Stage services before enabling them.
- Keep monitoring as its own concern.
- Make the repo easier to understand before making it more powerful.
