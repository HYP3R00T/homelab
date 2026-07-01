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

- `vault`: secret storage backend for the cluster
- `external-secrets`: syncs Kubernetes secrets from Vault into workloads
- `cloudflared`: consumes synced secrets to expose selected services externally

## Dependency chain

```text
infrastructure
└── vault
    └── external-secrets
        └── cloudflared
```

The rollout wiring for that chain lives in:

- `clusters/lab/infrastructure.yaml`
- `infrastructure/lab/flux/core.yaml`
- `infrastructure/lab/flux/vault.yaml`
- `infrastructure/lab/flux/external-secrets.yaml`
- `infrastructure/lab/flux/cloudflared.yaml`
