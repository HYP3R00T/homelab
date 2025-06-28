# 🏡 homelab

A production-grade, self-hosted Kubernetes homelab powered by [k3s](https://k3s.io) and [FluxCD](https://fluxcd.io), running declarative infrastructure with secrets management, monitoring, and a curated suite of personal apps.

> ⚙️ Built for reliability, automation, and modular GitOps workflows.

## 🧰 Stack Overview

| Layer           | Tooling                                 |
|----------------|------------------------------------------|
| Kubernetes     | [k3s](https://k3s.io)                    |
| GitOps         | [FluxCD](https://fluxcd.io)              |
| Secrets Mgmt   | [HashiCorp Vault](https://www.vaultproject.io) + [ESO](https://external-secrets.io) |
| Networking     | [Cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/) + [Traefik (in-built)](https://doc.traefik.io) |
| Monitoring     | [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) |
| App Packaging  | [Helm](https://helm.sh), [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/) |
| OS Environment | Ubuntu 24.04.2 LTS on Lenovo Legion Y540 |

## 📁 Repository Structure

```
.
├── apps/                # Application manifests (base/lab overlays)
├── cluster/             # Cluster-level definitions, Flux bootstrap
├── docs/                # Documentation site (MkDocs)
├── infrastructure/      # Infrastructure components (Vault, ESO, Cloudflared)
├── monitoring/          # Monitoring stack (Prometheus, Grafana)
├── mkdocs.yml           # MkDocs config for documentation site
└── README.md
```

> ✅ `base/` holds reusable blueprints.
> 🧪 `lab/` contains environment-specific overlays.

## 🚀 Deployed Applications

| App         | Purpose                        |
|-------------|--------------------------------|
| Homepage    | Custom home dashboard          |
| Linkding    | Bookmark manager               |
| Mealie      | Recipe management              |
| Vault       | Secrets management backend     |
| ESO         | Sync Vault secrets to K8s      |
| Cloudflared | Secure tunneling to cluster    |
| Prometheus + Grafana | Monitoring + Dashboards |

All apps are declaratively managed using Helm & Kustomize via FluxCD.

## 🔐 Secrets & Security

Secrets are managed using:
- **HashiCorp Vault** (deployed in-cluster)
- **External Secrets Operator (ESO)** using the Kubernetes auth method
- Cloudflared tunnels expose apps securely without port forwarding or public IPs

## 📦 GitOps Workflow

This homelab follows a pure GitOps model:

1. **All manifests are committed to Git**
2. **FluxCD watches the repo and applies changes**
3. **Secrets are synced via ESO from Vault**
4. **Each component is modular, reusable, and declaratively configured**

## 🖥️ Host Specs

| Spec       | Value                          |
|------------|---------------------------------|
| OS         | Ubuntu 24.04.2 LTS              |
| Machine    | Lenovo Legion Y540 (i5-9300H)   |
| Memory     | 16 GB                           |
| GPU        | NVIDIA GTX 1650 Mobile          |
| Cluster    | Bare-metal, single-node (k3s)   |

## 🧠 Philosophy

This setup is built for:
- **Learning** Kubernetes, GitOps, and security best practices
- **Running production-grade self-hosted tools**
- **Keeping everything declarative, minimal, and portable**

> Inspired by the principles of GitOps, Platform Engineering, and Zero Trust Access.

## 🤝 License

MIT – feel free to fork, clone, and adapt for your own lab!