---
icon: lucide/cloud
---

# Cloudflared

Cloudflared is the tunnel client used to expose selected services outside the homelab.

It is part of infrastructure because it is shared access plumbing, not a user-facing application.

## What it depends on

- External Secrets, through `gitops/clusters/lab/infrastructure-controllers.yaml`
- A synced Kubernetes secret named `cloudflared-secret`
- A Vault value at `cloudflared/tunnel` with the property `token`

## What depends on it

- Any application that you later choose to publish through a Cloudflare tunnel

## Where it is activated

- `gitops/clusters/lab/infrastructure-controllers.yaml`
- `gitops/clusters/lab/infrastructure-configs.yaml`
- `gitops/infrastructure/configs/lab/cloudflared/kustomization.yaml`
- `gitops/infrastructure/configs/lab/cloudflared/kustomization.yaml`
- `gitops/infrastructure/configs/lab/cloudflared/externalSecret.yaml`
- `gitops/infrastructure/configs/base/cloudflared/`

## Current repository intent

The repository expects this flow:

1. Vault stores the Cloudflare tunnel token.
2. External Secrets reads that value from Vault.
3. A Kubernetes secret named `cloudflared-secret` is created in the `cloudflared` namespace.
4. The Cloudflared deployment consumes that secret.

If any earlier step is missing, the Cloudflared deployment will not have the token it needs.
