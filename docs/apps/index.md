---
icon: lucide/layout-grid
---

# Applications

Applications are the user-facing destination of the platform. Shared concerns
such as ingress, secrets, and external access remain in the Services layer.

| Application | Status | Local access | Public access | Storage |
|---|---|---|---|---|
| [Homepage](homepage.md) | Active | `homepage.homelab.internal` | No | ConfigMap from Git; ephemeral logs |
| [Linkding](linkding.md) | Active | `linkding.homelab.internal` | `linkding.hyperoot.dev` | 10 GiB retained volume |

Both overlays are enabled by `gitops/apps/lab/kustomization.yaml` and reconcile
through the `apps` Flux Kustomization.
