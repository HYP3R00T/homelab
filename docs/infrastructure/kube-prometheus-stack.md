---
icon: lucide/chart-no-axes-combined
---

# Monitoring

kube-prometheus-stack provides cluster metrics, dashboards, and alerting through Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics, and the Prometheus Operator.

## Included configuration

| Property | Value |
|---|---|
| Status | Declared; waits for Vault bootstrap and monitoring credentials |
| Helm chart | `kube-prometheus-stack` `87.15.2` |
| Namespace | `monitoring` |
| Grafana | `http://grafana.homelab.internal` |
| Prometheus | `http://prometheus.homelab.internal` |
| Prometheus storage request | 10 GiB |
| Grafana storage request | 2 GiB |
| Alertmanager storage request | 2 GiB |
| Prometheus retention | 10 days, limited to 8 GB |

Grafana and Prometheus are exposed on the internal network through Traefik. Prometheus has a query UI but no account-based login page or session system. This repository protects the Prometheus ingress at the Traefik boundary with a Basic Auth middleware. Alertmanager remains cluster-internal.

## Credentials

Complete [Vault bootstrap](../runbooks/vault-bootstrap.md) first, including address setup, unseal, login, Terraform configuration, and a Ready ClusterSecretStore. Flux declares the ExternalSecrets but does not choose or populate their values.

Terraform manages these entries in the **external-secrets** KV v2 mount using private inputs in `iac/vault/terraform.tfvars`:

| Entry | Terraform input | Required properties |
| --- | --- | --- |
| `monitoring/grafana` | `grafana_credentials` | `username`, `password` |
| `monitoring/prometheus` | `prometheus_users` | `users`, containing one htpasswd bcrypt entry |

Choose the Grafana administrator username and password in the private inputs. The ExternalSecret maps the record into `grafana-admin`; there is no need to create an administrator inside a running container.

Generate the Prometheus entry on the workstation with `htpasswd -nB prometheus`, entering your chosen password at its hidden prompt. Paste the complete resulting `prometheus:<bcrypt-hash>` line into `prometheus_users` and keep the browser password in your password manager. The example includes the command and installation instructions for the workstation utility. The input accepts the hash line, not a plaintext password.

Review and apply the Vault Terraform plan as described in [Vault bootstrap](../runbooks/vault-bootstrap.md). If either record already exists outside Terraform, preserve its values in the private inputs and import it before planning:

```shell
terraform -chdir=iac/vault import vault_kv_secret_v2.grafana external-secrets/data/monitoring/grafana
terraform -chdir=iac/vault import vault_kv_secret_v2.prometheus external-secrets/data/monitoring/prometheus
```

Import only records that exist. Terraform owns each complete record, so preserve any needed values before adopting it and change the private inputs rather than editing managed records directly. Keep inputs, hashes, plans, state, and backups outside Git.

After applying, verify delivery and installation:

```shell
kubectl -n monitoring get externalsecrets
kubectl -n flux-system get kustomizations
kubectl -n monitoring get helmrelease,pods,pvc
```

Expect both ExternalSecrets Ready, followed by the monitoring chart and Flux groups. Synchronization can wait for the controller retry or refresh interval. Configure [local access](../setup/local-access.md) to open Grafana and Prometheus with the chosen credentials.

## Resource budget

The six explicitly configured component requests total 1408 MiB RAM, excluding sidecars and other overhead. Prometheus requests 768 MiB and has a 2 GiB limit. Existing requests and limits are retained for the first trial; measure the whole VM, Vault/ESO, and monitoring before changing allocations. Node and per-pod measurements are required; no capacity reservation for future agent work is assumed.

## Storage and retention

All three claims use the non-default `local-path-retain` StorageClass, provided by the existing K3s provisioner. PV reclaim policy and StatefulSet claim retention are both Retain. Prometheus requests 10 GiB, but the local provisioner does not enforce PVC capacity as a filesystem quota. The separate 8 GB Prometheus retention-size limit leaves headroom for the WAL and compaction on the shared VM filesystem; filesystem free space must also be monitored.

Grafana persists its database and user changes in a 2 GiB claim. Alertmanager uses a 2 GiB claim so silences survive restarts. These metrics and dashboards are operational data, not a substitute for application or Vault backups.

## Ecosystem coverage

The stack installs monitors and default dashboards for Kubernetes, kubelet, CoreDNS, node-exporter, and kube-state-metrics. Additional monitor resources collect metrics from:

- Flux controllers and Flux Operator
- External Secrets controllers
- Traefik
- Vault

Prometheus discovers `ServiceMonitor` and `PodMonitor` resources across all namespaces. The CloudNativePG operator PodMonitor is included in the monitor set; the monitoring-monitors group waits for CNPG as well as the monitoring chart.

K3s embeds its control-plane processes and uses its default datastore in this setup. Separate scheduler, controller-manager, etcd, and kube-proxy targets and their related rules are disabled to avoid false-down targets. Kubernetes API, kubelet, node, and workload visibility remain enabled.

## Notifications

Alertmanager remains installed, but its route points to a null receiver with no external integrations. Notification destinations and thresholds will be discussed separately. A successful installation does not mean alerts have been delivered.

## Repository locations

All monitoring resources live under the single infrastructure service directory `gitops/infrastructure/kube-prometheus-stack`. Individual resources remain in separate YAML files. The secrets and monitors subdirectories preserve the required readiness boundaries.

- Chart source/release: `gitops/infrastructure/kube-prometheus-stack/helm-repository.yaml` and `gitops/infrastructure/kube-prometheus-stack/helm-release.yaml`
- Authenticated Prometheus ingress: `gitops/infrastructure/kube-prometheus-stack/prometheus-ingress.yaml` and `gitops/infrastructure/kube-prometheus-stack/prometheus-middleware.yaml`
- Existing allocations and retained-storage settings: `gitops/infrastructure/kube-prometheus-stack/values.yaml`
- Vault-backed credentials: `gitops/infrastructure/kube-prometheus-stack/secrets/grafana-external-secret.yaml` and `gitops/infrastructure/kube-prometheus-stack/secrets/prometheus-external-secret.yaml`; namespace: `gitops/infrastructure/kube-prometheus-stack/secrets/namespace.yaml`
- Custom ecosystem monitors: `gitops/infrastructure/kube-prometheus-stack/monitors`
- Activation and dependencies: `gitops/clusters/lab`

See [rollout](../runbooks/gitops-rollout.md) and [storage recovery](../runbooks/storage-recovery.md) for verification and data lifecycle. Credential values and notification destinations are operator-managed, not generated by these manifests.

See the [kube-prometheus-stack chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) and [Prometheus documentation](https://prometheus.io/docs/introduction/overview/) for upstream component behavior.
