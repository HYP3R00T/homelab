---
icon: lucide/key-round
---

# External Secrets

External Secrets Operator reads values from an external secret backend and creates ordinary Kubernetes `Secret` objects for workloads.

In this repository, it is configured to read from Vault through a `ClusterSecretStore`.

## What it depends on

- Vault, through `clusters/lab/vault.yaml`
- The Vault-backed store definition in `infrastructure/lab/external-secrets/clusterSecretStore.yaml`

## What depends on it

- `cloudflared`, through `infrastructure/lab/cloudflared/externalSecret.yaml`
- Any future workload that should receive secrets from Vault instead of storing them in Git

## Where it is activated

- `clusters/lab/external-secrets.yaml`
- `infrastructure/lab/external-secrets/kustomization.yaml`
- `infrastructure/base/external-secrets/`

## Current repository intent

The repository already points External Secrets at Vault:

- Vault address: `vault.vault.svc.cluster.local:8200`
- secret path: `external-secrets`
- auth role: `eso`

That means the Kubernetes side is wired, but it still depends on Vault being bootstrapped to match those settings.
