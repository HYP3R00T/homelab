# Homelab

This homelab uses one Ubuntu VM running K3s. Flux manages service manifests from the main branch. Homepage and Linkding are independent of the secret and monitoring bootstrap chain.

## Configuration at a glance

| Area | Owner | Included configuration |
| --- | --- | --- |
| Cluster platform | K3s | CoreDNS, Traefik, ServiceLB, Local Path Provisioner, Metrics Server |
| Applications | Flux apps group | Homepage and Linkding |
| Shared infrastructure | Flux infrastructure group | Retained storage class and Flux UI ingress |
| Secret delivery | Flux secrets and secret-store groups | Vault, ESO, and the Vault ClusterSecretStore |
| Monitoring | Flux monitoring groups | Secret delivery, kube-prometheus-stack, custom monitors |
| Optional workloads | Not activated | Cloudflared, CloudNativePG, Postiz |

Vault and monitoring are declared in the entrypoint, but a fresh cluster cannot complete their bootstrap automatically. See [rollout](runbooks/gitops-rollout.md) before merging changes to the watched branch.

## Where to start

- [Platform](platform/index.md) explains K3s ownership.
- [Architecture](architecture/index.md) explains traffic and secret dependencies.
- [Repository structure](gitops/repository-structure.md) describes the apps and infrastructure service areas.
- [Reconciliation](gitops/reconciliation.md) describes Flux dependencies.
- [Services](services/index.md) documents shared capabilities.
- [Applications](apps/index.md) lists the enabled applications.
- [Storage recovery](runbooks/storage-recovery.md) covers retained data and backups.

The manifests are the source of truth for declared state. A configured service is not proof of a successful rollout; check Flux readiness and the live workload.
