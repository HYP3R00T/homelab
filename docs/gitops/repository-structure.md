---
icon: lucide/folder-tree
---

# Repository structure

Use two service areas: apps for end-user applications, and infrastructure for administrative or shared platform services. Within an area, each service owns a directory with one YAML file per Kubernetes resource rather than duplicated base and environment overlays.

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
    cloudflared/            # public HTTPS for Shoutrrr only
  clusters/lab/
    flux-system/
    apps.yaml               # one file per Flux group
    infrastructure.yaml
    secrets.yaml
    secret-store.yaml
    cnpg.yaml
    shoutrrr.yaml
    cloudflared.yaml
    kustomization.yaml
```

Use one YAML file per Kubernetes object, with descriptive names such as deployment.yaml, service.yaml, or redis-deployment.yaml. Do not combine resources into multi-document manifests. `kustomization.yaml` assembles the service and generates ConfigMaps when needed. `values.yaml` is a Helm input, not a directly applied Kubernetes object. Homepage keeps its configuration files because the application consumes them individually.

A directory boundary expresses ownership; a Flux group expresses readiness.

Only paths reachable from the cluster entrypoint are reconciled.

Names and storage ownership matter more than directory names. Moving an existing object between directories within the same Flux group need not recreate it. Moving ownership between Flux groups requires a deliberate inventory/pruning migration.
