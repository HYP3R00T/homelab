---
icon: lucide/layers
---

# Infrastructure

Infrastructure supports and administers the applications. This category includes K3s-packaged components and Flux-managed additions; it is broader than the Flux group named `infrastructure`, which reconciles only the core bundle.

| Component | What it does | Owner / activation | Required local setup |
| --- | --- | --- | --- |
| [Flux](flux.md) | Reconciles Git configuration and exposes status | Flux Operator; included instance | Bootstrap operator/instance and configure hostname access |
| [Traefik](traefik.md) | Routes HTTP requests to Services | K3s packaged component | Hosts mappings and matching Ingress |
| [Local Path Provisioner](local-path-provisioner.md) | Allocates node-local persistent volumes | K3s; extra retained class from Flux | Backups and recovery planning |
| [Metrics Server](metrics-server.md) | Supplies current pod/node resource readings | K3s packaged component | Verify metrics API |
| [Vault](vault.md) | Stores credential values outside Git | Flux secrets group | Initialize, unseal, configure authentication, populate values |
| [External Secrets](external-secrets.md) | Synchronizes Vault values to Kubernetes Secrets | Flux secrets/store groups | Working Vault authentication and secret values |
| [Monitoring](kube-prometheus-stack.md) | Stores metrics, renders dashboards, evaluates alerts | Flux monitoring groups | Vault-backed credentials; no notification destination configured |
| [CloudNativePG](cloudnative-pg.md) | Manages PostgreSQL clusters | Flux cnpg group | Application credentials and database bootstrap |
| [Cloudflared](cloudflared.md) | Public HTTPS for Shoutrrr | Dedicated Flux group | Vault-backed tunnel credential and Cloudflare DNS route |

The absence of a pod can mean an intentionally inactive component or a dependency waiting for configuration. Use [reconciliation](../gitops/reconciliation.md) and the [rollout runbook](../runbooks/gitops-rollout.md) to tell the difference. These pages describe declared ownership, not a permanent snapshot of live status.
