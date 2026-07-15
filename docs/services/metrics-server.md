---
icon: lucide/gauge
---

# Metrics Server

Metrics Server collects recent CPU and memory usage from each kubelet and
publishes it through the Kubernetes Resource Metrics API. Homepage uses that
API for its aggregate cluster information widget. Per-node display is hidden
while the homelab has only one node. Kubernetes can also use the same API for
`kubectl top` and resource-based autoscaling.

## Current status

| Property | Value |
|---|---|
| Status | Enabled |
| Helm chart | `metrics-server` `3.13.1` |
| Application version | `0.8.1` |
| Namespace | `kube-system` |
| API | `metrics.k8s.io/v1beta1` |
| Replicas | 1 |

Metrics Server provides short-lived resource measurements. Prometheus remains
the system for retained metrics, dashboards, and alerts.

## Talos kubelet TLS

The Talos kubelet certificate on this node is valid for the node hostname,
`talos-9xy-zhb`, rather than its IP address. The lab overlay therefore makes
Metrics Server connect through that hostname and maps it to `192.168.0.50`
inside the Metrics Server pod.

The kubelet's public CA certificate is stored in the
`metrics-server-kubelet-ca` ConfigMap and mounted read-only. Metrics Server
validates the kubelet certificate with that CA. The deployment does not use
`--kubelet-insecure-tls`. The Kubernetes API aggregation connection also
validates a Helm-managed Metrics Server certificate.

The current kubelet CA expires on 14 July 2027. After reinstalling Talos or
rotating its kubelet certificate authority, replace the public CA in
`kubelet-ca-config-map.yaml` before reconciling Metrics Server. Also update the
hostname and IP in `helm-release-patch.yaml` if the node identity changes.

## Verification

Confirm that the aggregated API is available:

```shell
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

Inspect human-readable resource usage:

```shell
kubectl top nodes
kubectl top pods --all-namespaces
```

## Repository locations

- Reusable Helm release: `gitops/monitoring/controllers/base/metrics-server`
- Lab values and kubelet trust: `gitops/monitoring/controllers/lab/metrics-server`
- Homepage widget: `gitops/apps/lab/homepage/configs/widgets.yaml`
