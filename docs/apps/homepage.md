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

## Dashboard sections

The dashboard is organized by responsibility:

- **Applications** contains user-facing workloads such as Linkding.
- **Platform** contains Flux Operator, Vault, Traefik, and the Cloudflare Zero
  Trust administration console.
- **Observability** contains Grafana and Prometheus.
- **AI Assistants** contains external AI and developer-assistant services.

Service descriptions make each destination explicit. Internal health endpoints
are used for site monitoring where they do not require credentials. Prometheus
and Traefik use Homepage's credential-free service widgets. Grafana and
Cloudflare widgets are intentionally omitted because they require credentials
or API tokens; adding either requires an approved secret-delivery design.

## Repository locations

- Reusable workload: `gitops/apps/base/homepage`
- Lab overlay and ingress: `gitops/apps/lab/homepage`
- Activation: `gitops/apps/lab/kustomization.yaml`
- Flux entrypoint: `gitops/clusters/lab/apps.yaml`

## Dependencies

- Flux applies the application overlay.
- Traefik serves the local hostname.
- CoreDNS and local DNS resolve cluster and homelab names.

Only deployed local web interfaces are listed. Platform components without a
web interface, such as MetalLB, External Secrets Operator, CloudNativePG,
NVIDIA GPU Operator, and Local Path Provisioner, are represented through
Grafana and Prometheus rather than misleading dashboard links.
