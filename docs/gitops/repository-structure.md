---
icon: lucide/folder-tree
---

# Repository structure

Use two service areas: apps for end-user applications, and infrastructure for administrative or shared platform services. Monitoring belongs to infrastructure even though Grafana and Prometheus have web interfaces. Within an area, each service owns a directory with one YAML file per Kubernetes resource rather than duplicated base and environment overlays.

```text
gitops/
  apps/
    homepage/
    linkding/
    shoutrrr/               # SQLite trial, waits for retained storage and Vault
  infrastructure/
    core/                   # retained storage class and Flux ingress
    secrets/                # assembles Vault and ESO
    vault/
    external-secrets/
    secret-store/           # waits for ESO and manual Vault bootstrap
    cnpg/                   # included operator
    cloudflared/            # inactive
    kube-prometheus-stack/  # Helm source/release, values, ingress
      secrets/              # namespace and ExternalSecrets
      monitors/             # CRs requiring Prometheus Operator
  clusters/lab/
    flux-system/
    apps.yaml               # one file per Flux group
    infrastructure.yaml
    secrets.yaml
    secret-store.yaml
    monitoring-secrets.yaml
    monitoring.yaml
    monitoring-monitors.yaml
    cnpg.yaml
    shoutrrr.yaml
    kustomization.yaml
```

Use one YAML file per Kubernetes object, with descriptive names such as deployment.yaml, service.yaml, or redis-deployment.yaml. Do not combine resources into multi-document manifests. `kustomization.yaml` assembles the service and generates ConfigMaps when needed. `values.yaml` is a Helm input, not a directly applied Kubernetes object. Homepage keeps its configuration files because the application consumes them individually.

The monitoring directory is one service structure, but its three Flux groups remain separate: secrets must synchronize before the chart installs, and custom monitors require the chart's CRDs. A directory boundary expresses ownership; a Flux group expresses readiness.

Only paths reachable from the cluster entrypoint are reconciled. The CloudNativePG operator monitor lives in `gitops/infrastructure/kube-prometheus-stack/monitors/cnpg-pod-monitor.yaml`; its group waits for the operator namespace and Prometheus CRDs.

Names and storage ownership matter more than directory names. Moving an existing object between directories within the same Flux group need not recreate it. Moving ownership between Flux groups requires a deliberate inventory/pruning migration.
