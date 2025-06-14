---
title: HashiCorp Vault Deployment
---

This document explains the deployment of HashiCorp Vault in the homelab Kubernetes cluster, referencing the configuration and manifests in the codebase.

## Overview

Vault is deployed using Helm and managed with Flux and Kustomize. The deployment is split into `base` and `lab` overlays for reusability and environment-specific configuration.

## Directory Structure

- `infrastructure/base/vault/`: Base manifests for Vault (namespace, PVC, HelmRelease, HelmRepository)
- `infrastructure/lab/vault/`: Lab-specific overlay (persistent volume, values, configMap)
- `infrastructure/lab/kustomization.yaml`: Includes Vault as a resource

## Deployment Details

### 1. Namespace

Defined in `namespace.yaml` to isolate Vault resources:

```yaml
kind: Namespace
metadata:
  name: vault
```

### 2. Persistent Storage

- **PersistentVolume**: Defined in `lab/vault/persistentVolume.yaml` for local storage on the `homelab` node.
- **PersistentVolumeClaim**: Defined in `base/vault/persistentVolumeClaim.yaml` and referenced by the Helm chart.

### 3. HelmRelease & Repository

- **HelmRepository**: Points to HashiCorp's Helm repo (`repository.yaml`).
- **HelmRelease**: Deploys Vault using the chart, with values loaded from a ConfigMap (`release.yaml`).

### 4. Configuration Values

- `values.yaml` in `lab/vault/` customizes the Vault deployment (standalone mode, UI enabled, ingress, resource limits, etc).
- The ConfigMap is generated via Kustomize's `configMapGenerator`.

### 5. Ingress

- Vault UI is exposed via Traefik ingress at `vault.homelab.internal`.

## How to Apply

1. Ensure the persistent volume path exists on the node.
2. Apply the base and lab overlays using Kustomize or Flux.
3. Vault will be available at the configured ingress address.

## References

- [Vault Helm Chart](https://github.com/hashicorp/vault-helm)
- [Vault Kubernetes Docs](https://developer.hashicorp.com/vault/docs/platform/k8s)

## Related Files

- `infrastructure/base/vault/`
- `infrastructure/lab/vault/`
- `infrastructure/lab/kustomization.yaml`
