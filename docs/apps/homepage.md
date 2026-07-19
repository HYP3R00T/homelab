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

- **Applications** contains user-facing workloads such as Linkding and Postiz.
- **Infrastructure & Monitoring** contains Flux Operator, Vault, Traefik,
  Grafana, and Prometheus.
- **AI Assistants** contains external AI and developer-assistant services.

These names remain as configuration keys, but their visual headers are hidden
to keep the dashboard compact. Service cards also omit descriptions. Icons use
Homepage's built-in Dashboard Icons integration when the service has a matching
asset. AI Fiesta retains its own logo because Dashboard Icons does not provide
one. Internal health endpoints are used for site monitoring where they do not
require credentials. Prometheus and Traefik service widgets show summary
metadata on their cards. Equal-height cards keep every service in that row
aligned with those two widget-enabled cards.

Quick Launch is enabled for keyboard navigation. Start typing anywhere on the
dashboard to search service and bookmark names. Internet search suggestions are
excluded so results remain focused on configured dashboard items. A launcher
button is also available in the bottom-right corner on mobile layouts.

Information widgets show host resources, aggregate Kubernetes cluster usage,
current weather for Jagatsinghpur, Odisha, and the local time. Per-node usage is
hidden while the cluster has only one node. The weather data comes from
Open-Meteo in metric units and does not require an API key.

Homepage uses Kubernetes `cluster` mode with its dedicated ServiceAccount and
read-only RBAC. Ingress discovery is enabled. The Kubernetes information widget
uses Metrics Server to display cluster and node CPU and memory usage.

## Local preview

Preview the exact GitOps configuration in WSL before deploying it to the
cluster. The preview uses the same pinned Homepage image, mounts
the tracked files from `gitops/apps/lab/homepage/configs` individually as
read-only files and does not mount the Docker socket. The canonical Kubernetes
configuration remains in `cluster` mode, so its expected API error can appear
in the Docker preview because no in-cluster ServiceAccount exists there. The
intentionally empty `proxmox.yaml` is tracked and mounted in both environments
so Homepage does not need to generate it during startup.

Docker Desktop must be running with this WSL distribution enabled under
**Settings > Resources > WSL Integration**. Then start the preview from the
repository root:

```shell
mise run homepage-preview
```

Open `http://localhost:3000`. Edit files under
`gitops/apps/lab/homepage/configs`, then use Homepage's refresh control or
refresh the browser to inspect the result. Stop a foreground preview with
`Ctrl+C`, then remove its container and network with:

```shell
mise run homepage-preview-stop
```

Links remain usable when the WSL workstation can resolve the homelab domains.
Server-side site monitors and service widgets that use `*.svc.cluster.local`
addresses will show unavailable in Docker because those names exist only
inside Kubernetes; that is expected and does not affect layout testing.

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
Cloudflared, NVIDIA GPU Operator, and Local Path Provisioner, are represented
through Grafana and Prometheus rather than misleading dashboard links.
