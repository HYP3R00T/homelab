---
icon: lucide/signpost
---

# Traefik

Traefik is the default Kubernetes ingress controller for local homelab
hostnames. MetalLB exposes it on `192.168.0.60`.

## Current implementation

| Property | Value |
|---|---|
| Helm chart | `traefik` `41.0.2` |
| Namespace | `traefik` |
| Ingress class | `traefik` (default) |
| Service type | LoadBalancer |
| External address | `192.168.0.60` |
| Dashboard route | `traefik.homelab.internal` |

Traefik watches Kubernetes Ingress resources and publishes the address of its
own Service. Homepage, Linkding, and Vault define local routes through it.

## Repository locations

- Helm release and OCI source: `gitops/infrastructure/controllers/base/traefik`
- Lab values: `gitops/infrastructure/controllers/lab/traefik`
- Application ingresses: `gitops/apps/lab`
- Vault ingress values: `gitops/infrastructure/configs/lab/vault/values.yaml`

## Dependencies

Traefik depends on MetalLB for LAN exposure. Applications depend on Traefik for
local hostname routing. Public Linkding traffic bypasses Traefik and travels
directly from Cloudflared to the Linkding Service.
