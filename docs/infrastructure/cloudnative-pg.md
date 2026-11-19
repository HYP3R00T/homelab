---
icon: lucide/database
---

# CloudNativePG

CloudNativePG manages PostgreSQL instances and their lifecycle. The `cnpg` Flux group installs chart `0.29.0` in namespace `cnpg`, independently of Vault bootstrap. The `postiz` group waits for the operator and the secret store before applying the application database resources.

The operator is infrastructure; Postiz's Cluster and Database resources belong to the application. This setup uses one PostgreSQL instance with three logical databases, not one server for each database. The operator requests 100m CPU and 128 MiB memory, with limits of 500m CPU and 256 MiB memory.

## Configuration and monitoring

Operator resources are under `gitops/infrastructure/cnpg`; its activation is `gitops/clusters/lab/cnpg.yaml`. The application resources are under `gitops/apps/postiz`. The operator PodMonitor is assembled by the monitoring-monitors group, which waits for both CNPG and the monitoring chart.

The Postiz database uses the retained local StorageClass. Review [storage recovery](../runbooks/storage-recovery.md) before changing database storage. No automatic database backup is configured by this installation.

## Verify

```shell
flux get kustomizations cnpg postiz
kubectl -n cnpg get helmrelease,pods
kubectl -n postiz get cluster,database,pods,pvc
```

A ready operator does not prove that its application database is ready. Database creation also requires the Vault-backed credentials. Follow [Postiz bootstrap](../apps/postiz/index.md#bootstrap-prerequisites) and [CloudNativePG documentation](https://cloudnative-pg.io/docs/) for database operations and backup planning.
