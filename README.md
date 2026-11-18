# Homelab

A private, single-node Ubuntu K3s homelab managed with Flux, Kustomize, and Helm. The VM has 4 vCPUs and approximately 5.28 GiB RAM. Configuration is kept small so application and platform costs can be measured before adding workloads.

## What stays

| Area | Configuration | Activation |
| --- | --- | --- |
| Apps | Homepage and Linkding | Enabled independently of secret infrastructure |
| K3s | Traefik, ServiceLB, CoreDNS, local storage, Metrics Server | Packaged and managed by K3s, not duplicated in GitOps |
| Infrastructure | Retained storage class and Flux UI ingress | Enabled |
| Secrets | Vault, External Secrets, Vault store | Enabled in dependency order; manual Vault bootstrap required |
| Monitoring | Prometheus, Grafana, Alertmanager, exporters | Enabled after Vault credentials synchronize |
| Optional | Cloudflared, CloudNativePG, Postiz | Retained but not activated |

Enabled means included in the GitOps configuration, not that a fresh installation is already bootstrapped. Vault initialization, unseal, Kubernetes authentication, and monitoring credential values remain operator tasks. No credentials are committed.

## Structure

- `gitops/apps/<service>/`: applications used by end users.
- `gitops/infrastructure/<service>/`: administrative and shared platform services; `core/` contains storage and Flux ingress, and `secrets/` assembles Vault and ESO.
- `gitops/infrastructure/kube-prometheus-stack/`: the monitoring infrastructure, with its Helm resources and values at the root, and `secrets/` and `monitors/` subdirectories for readiness ordering.
- `gitops/clusters/lab`: individual Flux application-group files and their dependencies.
- `iac/vault/`: Vault authentication, policies, and role configuration.
- `docs/`: current ownership, activation, and operations.

Each Kubernetes resource has its own named YAML file, assembled by the service Kustomization. Helm values and Homepage configuration remain separate because they are inputs to generated ConfigMaps. There is one environment; unused base/lab layering has been removed.

## Access

Resolve these names to `192.168.0.61` on the workstation: `homepage.homelab.internal`, `linkding.homelab.internal`, `flux.homelab.internal`, `vault.homelab.internal`, `grafana.homelab.internal`, and `prometheus.homelab.internal`. K3s Traefik uses the VM's LAN address. Cloudflared is not active and no public route is enabled by this configuration.

## Operations

Start with [the rollout runbook](docs/runbooks/gitops-rollout.md), [Vault bootstrap](docs/runbooks/vault-bootstrap.md), and [persistent storage recovery](docs/runbooks/storage-recovery.md). Monitoring keeps the existing resource allocations and retention limits for the first measured trial. Notification delivery is deferred. New Vault and monitoring volumes use `local-path-retain`; Linkding's existing volume is untouched.

Changes are reviewed in small stages. Git history holds removed configuration; there is no archive tree. Committing or pushing a feature branch does not deploy it: Flux watches `main`.
