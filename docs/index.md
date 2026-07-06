---
icon: lucide/rocket
---

# Homelab

This page reflects the current live homelab architecture.

## Current Architecture

![Current homelab architecture](assets/images/homelab-current.svg)

### What this diagram shows

- Single-node Talos Linux Kubernetes cluster running on a Lenovo Legion Y540
- Flux CD as the GitOps control plane syncing this repository
- MetalLB advertising `192.168.0.60` on the local network
- Traefik as the default ingress controller behind that VIP
- Homepage and Linkding as the current user-facing workloads in `apps/lab`
- NVIDIA GPU Operator and Node Feature Discovery active on the node

### Source of truth

- Rendered asset: `docs/assets/images/homelab-current.svg`
- This page is a documentation snapshot. Flux manifests under `clusters/lab/`, `apps/lab/`, and `infrastructure/` remain the operational source of truth.
