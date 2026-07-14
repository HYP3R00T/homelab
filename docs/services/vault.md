---
icon: lucide/lock-keyhole
---

# Vault

Vault is the secret storage backend for this homelab.

Its job is to hold values that should not live directly in Git, such as API tokens that other services need at runtime.

## Current implementation

| Property | Value |
|---|---|
| Status | Active |
| Helm chart | `vault` `0.34.0` |
| Namespace | `vault` |
| Mode | Single-replica HA with integrated Raft storage |
| Local hostname | `vault.homelab.internal` |
| Persistent storage | 10 GiB retained local volume |
| Managed KV mount | `external-secrets` (KV v2) |

## What it depends on

- Core infrastructure from `gitops/clusters/lab/infrastructure-controllers.yaml`
- The Vault overlay in `gitops/infrastructure/configs/lab/vault`

## What depends on it

- `external-secrets`, through `gitops/clusters/lab/infrastructure-controllers.yaml`

## Where it is activated

- `gitops/clusters/lab/infrastructure-controllers.yaml`
- `gitops/clusters/lab/infrastructure-configs.yaml`
- `gitops/infrastructure/configs/lab/vault/kustomization.yaml`
- `gitops/infrastructure/controllers/base/vault/`

## Important note

Applying the Kubernetes manifests is only the first half of the setup.

External Secrets also needs Vault to be bootstrapped with:

- a KV mount for the shared secret path
- Kubernetes auth enabled
- a role for the External Secrets Operator
- policies that allow the operator to read the expected paths

The Terraform workspace under `iac/vault` manages this bootstrap. The broader
relationship is described in [Secrets flow](../architecture/secrets-flow.md).

Vault seals after a pod restart because no auto-unseal provider is configured.
Recovery keys, administrative tokens, Raft snapshots, Terraform state, and
secret values must remain outside Git.

A Talos or Kubernetes reinstall creates a new cluster CA and new service-account
tokens. Refresh the Vault Kubernetes auth inputs after a reinstall even when
the API endpoint and Terraform state are unchanged.

## Runbooks

- [Bootstrap Vault](../runbooks/vault-bootstrap.md)
- [Recover Vault](../runbooks/vault-recovery.md)
- [Store Cloudflared credentials in Vault](../runbooks/cloudflared-vault-credentials.md)
