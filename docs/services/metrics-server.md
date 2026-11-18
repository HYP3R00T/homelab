# Metrics Server

K3s supplies Metrics Server in `kube-system`. The separate Helm installation and Talos-specific kubelet certificate patches have been removed. Keep the packaged add-on enabled.

Homepage reads the metrics API for node and per-service CPU/memory. This provides live readings, not historical storage. Prometheus supplies the historical metrics and alerts.

```shell
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl top nodes
kubectl top pods -A
```

Homepage configuration lives in `gitops/apps/homepage/configs`. The generic container Resources widget is not used as a substitute for whole-node metrics.
