---
icon: lucide/key-round
---

# External Secrets

External Secrets Operator reads values from an external secret backend and creates ordinary Kubernetes `Secret` objects for workloads.

In this repository, it is configured to read from Vault through a `ClusterSecretStore`.

## What it depends on

- Vault, through `gitops/clusters/lab/infrastructure-configs.yaml`
- The Vault-backed store definition in `gitops/infrastructure/configs/lab/external-secrets/clusterSecretStore.yaml`

## What depends on it

- `cloudflared`, through `gitops/infrastructure/configs/lab/cloudflared/externalSecret.yaml`
- Any future workload that should receive secrets from Vault instead of storing them in Git

## Where it is activated

- `gitops/clusters/lab/infrastructure-controllers.yaml`
- `gitops/clusters/lab/infrastructure-configs.yaml`
- `gitops/infrastructure/controllers/lab/external-secrets/kustomization.yaml`
- `gitops/infrastructure/controllers/base/external-secrets/`

## Vault integration

The repository already points External Secrets at Vault:

- Vault address: `vault.vault.svc.cluster.local:8200`
- secret path: `external-secrets`
- auth role: `eso`

The Terraform workspace under `iac/vault` creates the matching mount, auth
backend, policy, and role. The current Cloudflared integration reads the
`credentials` property from `cloudflared/tunnel` and writes it to the
`credentials.json` key in the `cloudflared-secret` Kubernetes Secret.

See [Secrets flow](../architecture/secrets-flow.md) for the cross-service data
path and [Bootstrap Vault](../runbooks/vault-bootstrap.md) for the setup
procedure.
