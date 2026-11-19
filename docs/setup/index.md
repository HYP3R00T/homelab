---
icon: lucide/list-ordered
---

# Set up the homelab

This is the first-install route for a similar private, single-node cluster. Read the configuration before applying it: Flux watches `main`, and the included monitoring stack requires manual Vault configuration. The repository provisions workloads, not the VM or its operating system.

## Follow the stages

| Stage | Action | Completion check |
| --- | --- | --- |
| 1 | [Prepare the workstation and VM](prerequisites.md) | Tools installed, repository reviewed, LAN node address known |
| 2 | [Install and inspect K3s](k3s.md) | Node Ready; packaged ingress, storage, and Metrics Server available |
| 3 | [Bootstrap Flux](flux.md) | Flux reads the intended repository and branch; apps and core reconcile |
| 4 | [Configure local hostname access](local-access.md) | Workstation resolves internal names to the node; HTTP requests reach Traefik |
| 5 | [Initialize Linkding](../apps/linkding.md#initial-setup) and review [Homepage](../apps/homepage.md#configuration) | Owner can sign in; dashboard cards match the intended services |
| 6 | [Bootstrap Vault](../runbooks/vault-bootstrap.md) | Vault initialized/unsealed; authentication configured; secret store Ready |
| 7 | [Populate monitoring credentials](../infrastructure/kube-prometheus-stack.md#credentials) | Both monitoring ExternalSecrets Ready; chart installed |
| 8 | [Bootstrap Shoutrrr](../apps/shoutrrr.md) | Vault credentials synchronized; SQLite and storage claims ready; first owner registered |
| 9 | [Verify the rollout](../runbooks/gitops-rollout.md#acceptance) | Intended groups and workloads Ready; data volumes bound |

The stages are not a single chain of application dependencies. Homepage and Linkding can work while Vault or monitoring is unfinished. Local hostname mappings are a workstation prerequisite for browser access, not a Kubernetes installation mechanism.

## After installation

Vault requires unsealing after its pod restarts unless an auto-unseal system is introduced separately. Retained local volumes require backups outside the VM. Check [Runbooks](../runbooks/index.md) for recovery and maintenance.

CloudNativePG is included independently. Complete [Shoutrrr bootstrap](../apps/shoutrrr.md) to supply its stable encryption key and register the first owner; this trial uses SQLite and does not require CNPG. Cloudflared remains disabled; no public tunnel is needed for LAN access. This guide does not install a LAN DNS server or expose the cluster publicly.
