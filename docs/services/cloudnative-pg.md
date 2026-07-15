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
| Database clusters | None defined |

The lab overlay is included by
`gitops/infrastructure/controllers/lab/kustomization.yaml`, and the HelmRelease
is part of the infrastructure controller health checks.

## Storage model

CloudNativePG creates a PVC for every PostgreSQL instance. The cluster uses the
default `local-path` StorageClass, backed by the Talos XFS user volume mounted
at `/var/mnt/local-path-provisioner`.

No PostgreSQL `Cluster` resource or database PVC is currently defined. The
installed operator therefore does not host application data.

See [Local Path Provisioner](local-path-provisioner.md) for the storage
boundary and operational constraints.
