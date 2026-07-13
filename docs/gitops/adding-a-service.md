---
icon: lucide/layers-3
---

# Adding a Service

This repository uses a `base/` and `lab/` overlay pattern so we can separate reusable service definitions from lab-specific decisions.

## At a glance

```text
gitops/
├── apps/
│   ├── base/
│   │   └── linkding/
│   └── lab/
│       └── linkding/
└── infrastructure/
    ├── base/
    │   └── traefik/
    └── lab/
        └── traefik/
```

The idea is simple:

- `base/` defines the service itself
- `lab/` adapts that service for this homelab

## What goes in `base/`

`base/` should contain the reusable building blocks of the service.

For an application, that usually means things like:

- `namespace.yaml`
- `deployment.yaml`
- `service.yaml`

For Helm-managed infrastructure, that usually means things like:

- namespace
- repository definition
- Helm release

Example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

This is how `gitops/apps/base/linkding/kustomization.yaml` works.

## What goes in `lab/`

`lab/` is the environment-specific overlay.

This is where we add the things that belong to this homelab in particular:

- namespace assignment for the overlay
- ingress
- persistent volumes or claims
- Helm values
- extra manifests needed only in this environment

Example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: linkding
resources:
  - ../../base/linkding/
  - persistentVolume.yaml
  - persistentVolumeClaim.yaml
  - ingress.yaml
```

This is how `gitops/apps/lab/linkding/kustomization.yaml` works.

## Helm-based services

For Helm-based services, the same pattern still applies.

The `base/` folder usually holds the generic Helm objects, while the `lab/` folder supplies values through a generated `ConfigMap`.

Example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: traefik
resources:
  - ../../base/traefik/

configMapGenerator:
  - name: traefik-values
    files:
      - values.yaml

generatorOptions:
  disableNameSuffixHash: true
```

This is the pattern used in `gitops/infrastructure/controllers/lab/traefik/kustomization.yaml` and `gitops/monitoring/lab/kube-prometheus-stack/kustomization.yaml`.

## How a new service gets added

When adding a new service, use this flow:

1. Decide where it belongs: `gitops/apps/`, `gitops/infrastructure/`, or `gitops/monitoring/`.
2. Create a `base/<service>/` folder for the reusable service definition.
3. Create a `lab/<service>/` folder for homelab-specific configuration.
4. Add the service to the parent `kustomization.yaml` in that layer.
5. Make sure the cluster entrypoint already points at that layer.

## Example flow

If we add a new application called `mealie`, the structure would look like:

```text
gitops/apps/
├── base/
│   └── mealie/
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── deployment.yaml
│       └── service.yaml
└── lab/
    └── mealie/
        ├── kustomization.yaml
        ├── ingress.yaml
        ├── persistentVolume.yaml
        └── persistentVolumeClaim.yaml
```

Then `gitops/apps/lab/kustomization.yaml` would include `mealie` as one of its resources.

## Why this pattern helps

This split keeps the repository easier to reason about.

- `base/` tells us what the service needs in general
- `lab/` tells us what this homelab adds or changes

That makes it easier to reuse, stage, review, and enable services without mixing common definitions with local decisions.

## Important distinction

Adding a service under `base/` and `lab/` does not make it live by itself.

The parent `kustomization.yaml` must include it, and the cluster entrypoint must reconcile that layer.

For example:

- `gitops/apps/lab/kustomization.yaml` decides which app overlays are part of `gitops/apps/lab`
- `gitops/infrastructure/controllers/lab/kustomization.yaml` decides which controller overlays are enabled
- `gitops/monitoring/lab/kustomization.yaml` decides which monitoring overlays are enabled

That is how a service can be present in the repository but still not active in the cluster.

## When ordering matters

Sometimes a service should not be bundled into a broad layer.

Secret backends are the clearest example. In this repository:

- `gitops/clusters/lab/infrastructure-controllers.yaml` reconciles `gitops/infrastructure/controllers/lab`
- `gitops/clusters/lab/infrastructure-configs.yaml` reconciles `gitops/infrastructure/configs/lab`
- `gitops/infrastructure/configs/lab/kustomization.yaml` bundles the shared infrastructure config overlays

This keeps `gitops/clusters/lab` small while still letting Flux express the real dependency chain through `dependsOn` inside the infrastructure layer itself.

```text
gitops/infrastructure
└── vault
    └── external-secrets
        └── cloudflared
```

Use this pattern when one service needs another service to be ready first.
