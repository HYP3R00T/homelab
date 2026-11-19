---
icon: lucide/gauge
---

# Metrics Server

Metrics Server supplies Kubernetes' current pod and node CPU/memory readings. K3s installs it in `kube-system`, so this GitOps tree does not install a duplicate server or the removed Talos-specific certificate patches.

[Homepage](../apps/homepage.md) reads this metrics API for its current node and service indicators. Metrics Server does not retain historical measurements; [Prometheus and Grafana](kube-prometheus-stack.md) provide that separate capability.

## Setup and verification

Keep the K3s packaged add-on enabled. There is no browser interface or account to create. Verify the metrics API after installing K3s:

```shell
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl top nodes
kubectl top pods -A
```

Expect an available APIService and readings after the first collection interval. If `kubectl top` fails, resolve that before diagnosing Homepage's metric cards. See [K3s packaged components](https://docs.k3s.io/installation/packaged-components) and the [Metrics Server project](https://github.com/kubernetes-sigs/metrics-server) for upstream behavior.
