# CloudNativePG

CloudNativePG is retained at chart version 0.29.0 in `gitops/infrastructure/cnpg`, but no active Flux group includes it. Its optional PodMonitor is `monitor.yaml`, excluded from the service Kustomization so installing the operator does not require Prometheus CRDs.

The inactive Postiz bundle declares a CloudNativePG Cluster named postiz-postgres and Database resources for Temporal. That deployment therefore requires this operator; it is not an unused dependency that can simply be deleted while keeping the current Postiz design.

Before enabling Postiz, add a separate dependency-ordered group for CNPG, wait for the operator, prepare application credentials, and choose storage/backup settings. Do not activate Postiz merely by adding it to the independent Homepage/Linkding apps group. No database deployment is part of the cleanup rollout.
