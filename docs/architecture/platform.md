---
icon: lucide/server
---

# Platform

The reference deployment uses one Ubuntu VM with 4 vCPUs and approximately 5.28 GiB RAM. It is a resource-constrained, single-node cluster, not a highly available service. VM provisioning and the host's K3s installation are outside the GitOps manifests.

## One owner per layer

| Layer | Owner | Responsibility |
| --- | --- | --- |
| VM and operating system | Operator / hypervisor | CPU, memory, disk, LAN access, Ubuntu, host backups |
| Kubernetes baseline | K3s | Control plane, container runtime, CoreDNS, Traefik, ServiceLB, Local Path Provisioner, Metrics Server |
| Declared workloads | Flux | Applications, Vault/ESO, storage class, ingresses, monitoring |
| Vault configuration | Terraform and operator | Authentication, policy, KV mount, initial setup, secret values |
| Persistent data | Applications and operator | Databases, metrics, backups, recovery |

Keeping a single owner avoids running a second ingress controller, storage provisioner, or Metrics Server. The two GitOps areas are `gitops/apps` and `gitops/infrastructure`; monitoring belongs to Infrastructure even though Grafana has a web UI.

## Independent applications, explicit dependencies

Homepage and Linkding do not wait for the Vault bootstrap. Core infrastructure, including the Flux UI ingress, also stays available independently of monitoring. The secret store waits for Vault/ESO, monitoring credentials wait for the store, and the monitoring chart waits for those credentials. This makes the point of failure visible instead of relying on application crash loops.

A directory expresses component ownership. A Flux reconciliation group expresses readiness. The group named `infrastructure` reconciles only `infrastructure/core`; the Infrastructure documentation category also includes the separate secrets and monitoring groups. [Reconciliation](../gitops/reconciliation.md) owns the exact dependency graph.

## Capacity and persistence

Current readings are useful for finding expensive applications, but they do not establish historical peaks. Keep resource requests and limits alongside the manifests and use monitoring to assess actual cost before adding workloads. There is no reserved capacity for an agent server.

New Vault, monitoring, and Shoutrrr volumes use `local-path-retain`. Existing Linkding storage keeps its original claim. Local storage remains tied to this node, and Retain is not a backup or protection from K3s uninstall. See [storage recovery](../runbooks/storage-recovery.md).

CloudNativePG and Shoutrrr are included through dedicated Flux groups, with Shoutrrr waiting for retained storage and Vault readiness; SQLite runs inside its application container. Cloudflared publishes only Shoutrrr at `https://shoutrrr.hyperoot.dev`. Removed Talos, NVIDIA, and MetalLB configuration is available through Git history rather than maintained as a second deployment design.
