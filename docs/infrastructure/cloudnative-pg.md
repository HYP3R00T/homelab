---
icon: lucide/database
---

# CloudNativePG

CloudNativePG manages PostgreSQL instances and their lifecycle. The `cnpg` Flux group installs chart `0.29.0` in namespace `cnpg`, independently of Vault bootstrap. The operator remains available for future database workloads; no application PostgreSQL cluster is currently declared. Shoutrrr uses SQLite and does not depend on this operator.

The operator requests 100m CPU and 128 MiB memory, with limits of 500m CPU and 256 MiB memory. Operator resources are under `gitops/infrastructure/cnpg`; activation is `gitops/clusters/lab/cnpg.yaml`. Its PodMonitor is assembled by the monitoring-monitors group, which waits for both CNPG and the monitoring chart.

## Verify

```shell
flux get kustomizations cnpg
kubectl -n cnpg get helmrelease,pods
kubectl get clusters.postgresql.cnpg.io -A
```

A Ready operator is available to manage application databases; it does not create a database server by itself. When adding a PostgreSQL workload, declare its Cluster, credentials, storage, and backup policy in the application's bundle. Review [storage recovery](../runbooks/storage-recovery.md) and the [CloudNativePG documentation](https://cloudnative-pg.io/docs/) before creating persistent database resources.
