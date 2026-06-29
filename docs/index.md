---
icon: lucide/rocket
---

# Homelab

This page now reflects the current live homelab architecture rather than the older README summary.

## Current Architecture

![Current homelab architecture](assets/images/homelab-current.svg)

### What this diagram shows

- Single-node Talos Linux Kubernetes cluster running on a Lenovo Legion Y540
- Flux CD as the GitOps control plane syncing this repository
- MetalLB advertising `192.168.0.60` on the local network
- Traefik as the default ingress controller behind that VIP
- Homepage as the currently exposed user workload
- NVIDIA GPU Operator and Node Feature Discovery active on the node

### Source of truth

- Editable D2 source: `diagram/homelab-current.d2`
- Rendered asset: `docs/assets/images/homelab-current.svg`
