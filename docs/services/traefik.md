# Traefik

K3s manages Traefik in `kube-system`. Its LoadBalancer service uses K3s ServiceLB and the node's LAN address, `192.168.0.61`, on ports 80 and 443. No separate Flux HelmRelease or MetalLB deployment is required.

Application and infrastructure Ingress objects use `ingressClassName: traefik`. The retained monitoring PodMonitor selects `app.kubernetes.io/name=traefik` and `app.kubernetes.io/instance=traefik-kube-system`, and scrapes the existing metrics port 9100. Those labels and the enabled Prometheus endpoint were inspected on this cluster; recheck them after K3s upgrades.

The dashboard is not exposed by this repository. Homepage reports its pod metrics instead of requesting the removed standalone Traefik dashboard endpoint.

```shell
kubectl get deployment,service -n kube-system -l app.kubernetes.io/name=traefik
kubectl get ingress -A
```

[K3s networking documentation](https://docs.k3s.io/networking/networking-services) describes packaged-chart customization through HelmChartConfig if a later change needs it.
