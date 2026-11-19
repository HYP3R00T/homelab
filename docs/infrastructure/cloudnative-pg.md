---
icon: lucide/database
---

# CloudNativePG

CloudNativePG (CNPG) manages PostgreSQL clusters through Kubernetes custom resources. It is retained for the proposed Postiz stack but is **not activated** by the current Flux entrypoint.

The operator chart is pinned at `0.29.0` in `gitops/infrastructure/cnpg`. Its optional `monitor.yaml` PodMonitor is excluded from the Kustomization, so installing the operator does not itself require Prometheus CRDs.

## Relationship to Postiz

The inactive [Postiz architecture](../apps/postiz/architecture.md) declares one CNPG Cluster, `postiz-postgres`, and Database resources for Temporal persistence and visibility. These are logical databases in one PostgreSQL instance, not separate PostgreSQL servers.

Keeping the current Postiz design therefore requires the operator. Installing CNPG alone would not create that database; the Cluster and Database resources belong to the application bundle.

## Before activation

Prepare a separate Flux readiness boundary for the operator, wait for its CRDs and health, prepare the secret store and application credentials, and review database storage and backups. Activate Postiz through its own dependency-ordered group so it does not block the independent Homepage/Linkding group. No database activation is part of the current setup journey.

After a deliberate activation, check the operator and application separately with `kubectl get helmreleases -A` and `kubectl -n postiz get cluster,database,pods,pvc`. Use the [CloudNativePG documentation](https://cloudnative-pg.io/docs/) for database operations and backup planning; no automatic database backup is configured here.
