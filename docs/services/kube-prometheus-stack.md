---
icon: lucide/chart-no-axes-combined
---

# kube-prometheus-stack

kube-prometheus-stack provides cluster metrics, dashboards, and alerting through
Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics, and the
Prometheus Operator.

## Current status

| Property | Value |
|---|---|
| Status | Enabled |
| Helm chart | `kube-prometheus-stack` `87.15.2` |
| Namespace | `monitoring` |
| Grafana | `http://grafana.homelab.internal` |
| Prometheus storage request | 10 GiB |
| Grafana storage request | 2 GiB |
| Alertmanager storage request | 2 GiB |
| Prometheus retention | 10 days, limited to 8 GB |

Only Grafana is exposed through Traefik. Prometheus and Alertmanager remain
cluster-internal and can be reached temporarily with `kubectl port-forward`
when direct access is needed.

## Credentials

The Grafana administrator credential is stored at
`external-secrets/data/monitoring/grafana` in Vault. External Secrets writes it
to the `grafana-admin` Kubernetes Secret before Flux installs the chart. No
password is stored in Git.

Retrieve the password from an authenticated workstation when needed:

```shell
set -a
source .env
set +a
vault kv get -field=password -mount=external-secrets monitoring/grafana
```

## Storage and retention

All three claims use the `local-path` StorageClass. Prometheus requests 10 GiB,
but the local provisioner does not enforce PVC capacity as a filesystem quota.
The separate 8 GB Prometheus retention-size limit leaves headroom for the WAL
and compaction before the shared XFS user volume is endangered.

Grafana persists its database and user changes in a 2 GiB claim. Alertmanager
uses a 2 GiB claim so silences survive restarts. These metrics and dashboards
are operational data, not a substitute for application or Vault backups.

## Ecosystem coverage

The stack installs monitors and default dashboards for Kubernetes, kubelet,
CoreDNS, node-exporter, and kube-state-metrics. Additional monitor resources
collect metrics from:

- Flux controllers and Flux Operator
- CloudNativePG Operator
- External Secrets controllers
- NVIDIA DCGM Exporter
- Traefik
- Vault

Prometheus discovers `ServiceMonitor` and `PodMonitor` resources across all
namespaces. Future CloudNativePG database clusters should enable their own
`PodMonitor` in the `Cluster` specification.

Talos binds the scheduler and controller-manager metrics endpoints to loopback,
and etcd metrics require an explicit Talos machine configuration change.
Monitoring for those endpoints, plus kube-proxy, is disabled to avoid permanent
false-down targets. Kubernetes API, kubelet, node, and workload visibility
remain enabled.

## Repository locations

- Helm release: `gitops/monitoring/controllers/base/kube-prometheus-stack`
- Lab values: `gitops/monitoring/controllers/lab/kube-prometheus-stack`
- Ecosystem monitors: `gitops/monitoring/configs/base`
- Lab monitor activation: `gitops/monitoring/configs/lab`
- Grafana secret delivery: `gitops/monitoring/controllers/lab/kube-prometheus-stack`
