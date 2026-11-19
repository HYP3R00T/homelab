---
icon: lucide/route
---

# Traefik

Traefik is the cluster's HTTP ingress controller. K3s installs it in `kube-system`; this repository declares Ingress resources against the existing `traefik` class rather than installing another controller.

K3s ServiceLB makes its LoadBalancer service available on the node's LAN address. Traefik listens on ports 80 and 443, but the declared browser routes use HTTP; the presence of port 443 does not configure certificates for internal hostnames. MetalLB is not needed for this setup.

## Configuration and access

Follow [local access](../setup/local-access.md) to map hostnames to the actual node address. An Ingress then routes the hostname to the appropriate Kubernetes Service. The core bundle declares `traefik-dashboard-ingress-route.yaml`, routing the `web` entrypoint to Traefik's existing `api@internal` service. Open `http://traefik.homelab.internal/dashboard/` after reconciliation and hostname setup; the trailing slash is required. K3s already enables the dashboard internally, so no additional deployment, Service, or duplicate controller is needed.

This is an unauthenticated LAN administration route, following the homelab's current access model. It exposes the dashboard and its configuration API to clients that can reach the ingress; the hostname is not an access-control boundary. Keep it on the trusted network and do not forward this route publicly. It does not enable `api.insecure` or expose port 8080 through a new Service.

Homepage links to the dashboard while continuing to read pod statistics through Kubernetes; it does not need a Traefik API widget.

The monitoring PodMonitor selects `app.kubernetes.io/name=traefik` and `app.kubernetes.io/instance=traefik-kube-system`, using metrics port 9100. Recheck the packaged labels and metrics configuration after K3s upgrades.

## Verify

```shell
kubectl get deployment,service -n kube-system -l app.kubernetes.io/name=traefik
kubectl get ingress -A
kubectl -n kube-system get ingressroute traefik-dashboard
```

Expect the controller available, the service's node address, and matching Ingress hosts. A backend failure is separate from hostname resolution or ingress routing; [local-access troubleshooting](../setup/local-access.md#verify-resolution-and-routing) follows those boundaries.

Use [K3s networking documentation](https://docs.k3s.io/networking/networking-services) for packaged-chart customization through HelmChartConfig. Do not add a second Flux HelmRelease to customize the same controller.
