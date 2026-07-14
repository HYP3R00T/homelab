---
icon: lucide/chart-no-axes-combined
---

# kube-prometheus-stack

kube-prometheus-stack is the staged observability bundle for Prometheus,
Alertmanager, Grafana, exporters, and monitoring custom resources.

## Current status

| Property | Value |
|---|---|
| Status | Staged |
| Helm chart | `kube-prometheus-stack` `78.3.0` |
| Namespace | `monitoring` |
| Prometheus storage request | 10 GiB |
| Grafana storage request | 2 GiB |
| Alertmanager storage request | 2 GiB |

The overlay is commented out in `gitops/monitoring/lab/kustomization.yaml`, so
the Flux monitoring layer currently applies no monitoring workload.

## Before enabling

- Replace the static Grafana administrator credential in the values file with
  a secret delivered through Vault and External Secrets.
- Confirm a dynamic or local storage strategy for all requested claims.
- Review resource requests for the single-node cluster.
- Confirm ingress and authentication policy for Grafana, Prometheus, and
  Alertmanager.

## Repository locations

- Helm release: `gitops/monitoring/base/kube-prometheus-stack`
- Lab values: `gitops/monitoring/lab/kube-prometheus-stack`
- Activation switch: `gitops/monitoring/lab/kustomization.yaml`
