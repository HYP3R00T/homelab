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
├── apps/            # User-facing workloads
├── infrastructure/  # Shared platform capabilities
├── monitoring/      # Observability layer
├── clusters/        # Flux entrypoints for the lab cluster
└── docs/            # Documentation site
```

> ✅ `base/` holds reusable service definitions.
>
> 🧪 `lab/` holds homelab-specific overlays.
>
> 🎛️ `clusters/` decides what Flux actually reconciles.

## 🚀 Current State

### Active now

| Layer | Active services |
|-------|-----------------|
| Apps | `homepage`, `linkding` |
| Infrastructure | `metallb`, `traefik` |
| Monitoring | none enabled right now |

### Staged in the repository

- `vault`
- `external-secrets`
- `cloudflared`
- `cnpg`
- monitoring components

These exist in the repo because the design work is happening here first, but they are not all live in the cluster yet.

## 🧭 How It Flows

1. Manifests live in `apps/`, `infrastructure/`, and `monitoring/`.
2. `base/` defines the reusable service shape.
3. `lab/` adds homelab-specific values, ingress, storage, and overlays.
4. `clusters/lab/*.yaml` tells Flux what to reconcile and in what order.

## 📚 Documentation

- `docs/index.md` shows the current architecture
- `docs/repository-structure.md` explains how services are grouped
- `docs/adding-a-service.md` explains the `base/` and `lab/` overlay pattern
- `docs/services/` documents individual infrastructure services and dependencies

## 🧠 Philosophy

- Keep the cluster declarative.
- Separate apps from shared infrastructure.
- Stage services before enabling them.
- Keep monitoring as its own concern.
- Make the repo easier to understand before making it more powerful.
