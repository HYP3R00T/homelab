# Platform services

| Service | Owner | Configuration |
| --- | --- | --- |
| [Flux](flux.md) | Flux Operator | Existing reconciliation and embedded web UI |
| [Traefik](traefik.md) | K3s | Packaged ingress, no separate GitOps installation |
| [Local Path Provisioner](local-path-provisioner.md) | K3s | Default class plus GitOps retained class |
| [Metrics Server](metrics-server.md) | K3s | Live CPU and memory API |
| [Vault](vault.md) | Flux secrets group | Single-replica Raft, manual bootstrap/unseal |
| [External Secrets](external-secrets.md) | Flux secrets/store groups | Vault-backed Kubernetes Secrets |
| [Monitoring](kube-prometheus-stack.md) | Flux monitoring groups | Prometheus, Grafana, Alertmanager and collectors |
| [CloudNativePG](cloudnative-pg.md) | Not activated | Retained for Postiz |
| [Cloudflared](cloudflared.md) | Not activated | Retained optional public tunnel |

MetalLB and NVIDIA resources have been removed. Services included in GitOps can remain unready until their documented bootstrap steps are complete; this table describes ownership and activation rather than claiming a live rollout has already happened.
