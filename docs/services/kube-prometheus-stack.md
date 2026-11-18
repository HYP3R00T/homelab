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
| Status | Declared; waits for Vault bootstrap and monitoring credentials |
| Helm chart | `kube-prometheus-stack` `87.15.2` |
| Namespace | `monitoring` |
| Grafana | `http://grafana.homelab.internal` |
| Prometheus | `http://prometheus.homelab.internal` |
| Prometheus storage request | 10 GiB |
| Grafana storage request | 2 GiB |
| Alertmanager storage request | 2 GiB |
| Prometheus retention | 10 days, limited to 8 GB |

Grafana and Prometheus are exposed on the internal network through Traefik.
Prometheus has a query UI but no account-based login page or session system.
The Prometheus server can enforce experimental Basic Auth through a separate
web configuration file, but the Prometheus Operator API used by this stack
does not expose its `basic_auth_users` setting. The ingress is therefore
protected at the existing Traefik boundary with a Basic Auth middleware.
Alertmanager remains cluster-internal.

## Credentials

The operator owns these credential values. Creating the GitOps references does
not authorize writing anything to Vault. Before creating or rotating either
credential, ask whether the operator already has a password and wait for
explicit approval of the exact Vault operation.

The Grafana administrator credential is stored at
`external-secrets/data/monitoring/grafana` in Vault. External Secrets writes it
to the `grafana-admin` Kubernetes Secret before Flux installs the chart. No
password is stored in Git.

The Grafana username is `admin`. Retrieve its password from an authenticated
workstation when needed:

```shell
set -a
source .env
set +a
vault kv get -field=password -mount=external-secrets monitoring/grafana
```

To use an operator-selected Grafana password, collect it without echoing it and
write it only after explicit approval:

```shell
read -rs "GRAFANA_ADMIN_PASSWORD?Grafana password: "
printf '\n'
vault kv put -mount=external-secrets monitoring/grafana \
  username=admin password="$GRAFANA_ADMIN_PASSWORD"
unset GRAFANA_ADMIN_PASSWORD
```

Prometheus uses a separate credential stored at
`external-secrets/data/monitoring/prometheus`. External Secrets synchronizes
only the bcrypt `htpasswd` entry required by Traefik; the plaintext password
remains in Vault and is never copied to a Kubernetes Secret.

Retrieve its username and password with:

```shell
set -a
source .env
set +a
vault kv get -field=username -mount=external-secrets monitoring/prometheus
vault kv get -field=password -mount=external-secrets monitoring/prometheus
```

Prometheus requires an `htpasswd` entry in addition to the chosen password.
Generate that bcrypt entry and write the record only after explicit approval:

```shell
read -rs "PROMETHEUS_PASSWORD?Prometheus password: "
printf '\n'
PROMETHEUS_HASH="$(PROMETHEUS_PASSWORD="$PROMETHEUS_PASSWORD" python3 -c \
  'import bcrypt, os; print(bcrypt.hashpw(os.environ["PROMETHEUS_PASSWORD"].encode(), bcrypt.gensalt(rounds=12)).decode())')"
vault kv put -mount=external-secrets monitoring/prometheus \
  username=prometheus password="$PROMETHEUS_PASSWORD" \
  users="prometheus:$PROMETHEUS_HASH"
unset PROMETHEUS_PASSWORD PROMETHEUS_HASH
```

## Resource budget

The six explicitly configured component requests total 1408 MiB RAM, excluding sidecars and other overhead. Prometheus requests 768 MiB and has a 2 GiB limit. Existing requests and limits are retained for the first trial; measure the whole VM, Vault/ESO, and monitoring before changing allocations. Node and per-pod measurements are required; no capacity reservation for future agent work is assumed.

## Storage and retention

All three claims use the non-default `local-path-retain` StorageClass, provided by the existing K3s provisioner. PV reclaim policy and StatefulSet claim retention are both Retain. Prometheus requests 10 GiB,
but the local provisioner does not enforce PVC capacity as a filesystem quota.
The separate 8 GB Prometheus retention-size limit leaves headroom for the WAL
and compaction on the shared VM filesystem; filesystem free space must also be monitored.

Grafana persists its database and user changes in a 2 GiB claim. Alertmanager
uses a 2 GiB claim so silences survive restarts. These metrics and dashboards
are operational data, not a substitute for application or Vault backups.

## Ecosystem coverage

The stack installs monitors and default dashboards for Kubernetes, kubelet,
CoreDNS, node-exporter, and kube-state-metrics. Additional monitor resources
collect metrics from:

- Flux controllers and Flux Operator
- External Secrets controllers
- Traefik
- Vault

Prometheus discovers `ServiceMonitor` and `PodMonitor` resources across all
namespaces. The optional CloudNativePG monitor is retained with its inactive operator and is not part of the active monitor set.

K3s embeds its control-plane processes and uses its default datastore in this setup. Separate scheduler, controller-manager, etcd, and kube-proxy targets and their related rules are disabled to avoid false-down targets. Kubernetes API, kubelet, node, and workload visibility
remain enabled.

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

See [rollout](../runbooks/gitops-rollout.md) and [storage recovery](../runbooks/storage-recovery.md) for verification and data lifecycle. No passwords or receiver credentials have been generated by this change.
