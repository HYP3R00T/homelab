---
icon: lucide/panel-top
---

# Homepage

Homepage is the internal dashboard for links to homelab services and external
tools. It is active and intended for local-network use.

## Current implementation

| Property | Value |
|---|---|
| Image | `ghcr.io/gethomepage/homepage:v1.13.2` |
| Namespace | `homepage` |
| Service | `homepage:3000` |
| Local hostname | `homepage.homelab.internal` |
| Replicas | 1 |
| Persistence | Configuration from a generated ConfigMap; logs use `emptyDir` |

The workload uses a dedicated ServiceAccount and read-only RBAC so Homepage can
discover selected Kubernetes resources. Dashboard configuration, bookmarks,
widgets, CSS, and JavaScript live under `gitops/apps/lab/homepage/configs`.

## Repository locations

- Reusable workload: `gitops/apps/base/homepage`
- Lab overlay and ingress: `gitops/apps/lab/homepage`
- Activation: `gitops/apps/lab/kustomization.yaml`
- Flux entrypoint: `gitops/clusters/lab/apps.yaml`

## Dependencies

- Flux applies the application overlay.
- Traefik serves the local hostname.
- CoreDNS and local DNS resolve cluster and homelab names.

Homepage currently lists a Mealie shortcut even though no Mealie workload is
defined in this repository. Treat dashboard links as navigation configuration,
not proof that a workload is deployed.
