---
icon: lucide/database
---

# CloudNativePG

CloudNativePG provides a Kubernetes operator for PostgreSQL clusters. The
operator is enabled in the lab controller overlay; application database
clusters are defined separately when a workload needs PostgreSQL.

## Current status

| Property | Value |
|---|---|
| Status | Enabled in GitOps |
| Namespace | `cnpg` |
| Helm chart | `cloudnative-pg` |
| Chart version | `0.29.0` |
| Database clusters | `postiz-postgres` in the `postiz` namespace |

The lab overlay is included by
`gitops/infrastructure/controllers/lab/kustomization.yaml`, and the HelmRelease
is part of the infrastructure controller health checks.

## Storage model

CloudNativePG creates a PVC for every PostgreSQL instance. The cluster uses the
default `local-path` StorageClass, backed by the Talos XFS user volume mounted
at `/var/mnt/local-path-provisioner`.

The single-instance `postiz-postgres` cluster has a 10 GiB local volume. It
hosts the Postiz application database and the two databases required by
Temporal. CloudNativePG manages the `postiz` and `temporal` roles from
Vault-backed `kubernetes.io/basic-auth` Secrets.

See [Local Path Provisioner](local-path-provisioner.md) for the storage
boundary and operational constraints.
