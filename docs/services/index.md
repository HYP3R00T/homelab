---
icon: lucide/blocks
---

# Services

This section documents individual platform services.

Each page answers the same practical questions:

- what the service is for
- what it depends on
- what depends on it
- which files activate it in this repository

## Current pages

- [Vault](vault.md): secret storage backend for the cluster
- [External Secrets](external-secrets.md): syncs Kubernetes secrets from Vault
  into workloads
- [Cloudflared](cloudflared.md): consumes synced secrets to expose selected
  services externally

## Dependency chain

```text
infrastructure
└── vault
    └── external-secrets
        └── cloudflared
```

The rollout wiring for that chain lives in:

- `gitops/clusters/lab/infrastructure-controllers.yaml`
- `gitops/clusters/lab/infrastructure-configs.yaml`
- `gitops/infrastructure/configs/lab/kustomization.yaml`

For procedures, use the [Runbooks](../runbooks/index.md) section. For the
cross-service data path, see [Secrets flow](../architecture/secrets-flow.md).
