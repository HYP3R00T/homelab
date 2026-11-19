---
icon: lucide/vault
---

# Vault

Vault holds monitoring and application credential values outside Git. External Secrets reads approved paths and delivers them to workloads. This separates public deployment configuration from private values, while keeping Vault's initialization and recovery responsibilities explicit.

| Property | Configuration |
| --- | --- |
| Owner | Flux secrets group |
| Chart | `vault` `0.34.0` |
| Manifests | `gitops/infrastructure/vault` |
| Browser / workstation CLI | `http://vault.homelab.internal` |
| In-cluster service | `http://vault.vault.svc.cluster.local:8200` |
| Storage | One Raft replica; 10 GiB `vault-data` claim on `local-path-retain` |
| Resources | 100m CPU / 256 MiB requested; 500m CPU / 512 MiB limited |

## Initial configuration

Follow [Vault bootstrap](../runbooks/vault-bootstrap.md) in order: configure the workstation address, check initialization status, initialize only a new Vault, unseal, authenticate, configure the private Terraform inputs, and apply the workspace to populate Postiz and monitoring credentials.

The Helm chart does not perform those steps. Its health probes accept sealed and uninitialized responses, so a Ready pod or successful Helm release is not proof that Vault can serve secrets. The ClusterSecretStore is a stronger check of the authentication path.

`iac/vault` manages the Kubernetes authentication mount, reviewer configuration, KV v2 mount, ESO policy, service-account role, and the three Postiz/monitoring credential records. The injector is disabled because these workloads use External Secrets rather than Vault Agent injection. There is no configured auto-unseal provider.

## Restart and recovery

A pod restart requires manual unsealing with the existing shares; do not initialize again. A Kubernetes reinstall requires new CA and reviewer-token inputs even if the API address stays the same. Use [Vault recovery](../runbooks/vault-recovery.md) to refresh authentication or restore Terraform tracking.

The PVC and namespace have Flux pruning protection, but the single local Raft replica is not highly available. Retain does not protect it from host disk failure or a K3s uninstall. Back up the data and matching unseal material securely; neither is in Git.

## Verify

```shell
export VAULT_ADDR=http://vault.homelab.internal
vault status
kubectl get clustersecretstore vault
```

Expect `Initialized: true`, `Sealed: false`, and a Ready secret store after bootstrap. For CLI access, first follow [local access](../setup/local-access.md). See the [official Vault documentation](https://developer.hashicorp.com/vault/docs) for operational behavior and supported storage/recovery mechanisms.
