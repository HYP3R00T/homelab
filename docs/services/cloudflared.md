---
icon: lucide/cloud
---

# Cloudflared

Cloudflared is the tunnel client used to expose selected services outside the homelab.

It is part of infrastructure because it is shared access plumbing, not a user-facing application.

## Current implementation

| Property | Value |
|---|---|
| Status | Active |
| Image | `cloudflare/cloudflared:2026.7.1` |
| Namespace | `cloudflared` |
| Tunnel | Locally managed `homelab` tunnel |
| Credential source | Vault through External Secrets |
| Public hostname | `linkding.hyperoot.dev` |
| Origin | `linkding-service.linkding.svc.cluster.local:9090` |

## What it depends on

- External Secrets, through `gitops/clusters/lab/infrastructure-controllers.yaml`
- A synced Kubernetes secret named `cloudflared-secret`
- A Vault value at `cloudflared/tunnel`

## What depends on it

- Public access to Linkding at `linkding.hyperoot.dev`

## Where it is activated

- `gitops/clusters/lab/infrastructure-controllers.yaml`
- `gitops/clusters/lab/infrastructure-configs.yaml`
- `gitops/infrastructure/configs/lab/cloudflared/kustomization.yaml`
- `gitops/infrastructure/configs/lab/cloudflared/external-secret.yaml`
- `gitops/infrastructure/configs/base/cloudflared/`

## Current repository intent

The repository expects this flow:

1. Vault stores the locally managed tunnel credential JSON.
2. External Secrets reads that value from Vault.
3. A Kubernetes secret named `cloudflared-secret` is created in the `cloudflared` namespace.
4. The Cloudflared deployment mounts that secret as `credentials.json`.
5. A local configuration routes `linkding.hyperoot.dev` to the Linkding Service.

If any earlier step is missing, the Cloudflared connector cannot establish the
tunnel.

## Published services

- `linkding.hyperoot.dev` routes to
  `linkding-service.linkding.svc.cluster.local:9090`.

The cross-service relationship is described in
[Secrets flow](../architecture/secrets-flow.md).

## Runbooks

- [Create a Cloudflared tunnel](../runbooks/cloudflared-tunnel.md)
- [Store Cloudflared credentials in Vault](../runbooks/cloudflared-vault-credentials.md)
