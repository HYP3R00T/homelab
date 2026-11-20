---
icon: lucide/network
---

# Architecture

The homelab separates **Applications**, which people use directly, from **Infrastructure**, which supports and administers them. Both run on one Ubuntu VM. K3s owns its packaged components; Flux owns the additional declared resources.

[![Full-system architecture](../assets/diagrams/architecture.svg)](../assets/diagrams/architecture.svg)

[Open the architecture diagram at full size](../assets/diagrams/architecture.svg).

The overview shows Applications and Infrastructure within K3s, with K3s inside the Ubuntu VM. Persistent files live on the host. Packaged components, Kubernetes storage objects, storage policies, and bootstrap sequences are explained in the focused pages below rather than crowded into this diagram. Cloudflared publishes Shoutrrr over HTTPS; the remaining interfaces stay on the private LAN.

## Read the system by boundary

| Question | Explanation |
| --- | --- |
| What does the node run, and who owns it? | [Platform](platform.md) |
| How does a browser reach an application? | [Traffic flow](traffic-flow.md) |
| How do credentials reach workloads? | [Secrets flow](secrets-flow.md) |
| Why are application credentials waiting for Vault? | [Reconciliation](../gitops/reconciliation.md) |
| What survives a pod restart or a reinstall? | [Storage recovery](../runbooks/storage-recovery.md) |

Use [Applications](../apps/index.md) and [Infrastructure](../infrastructure/index.md) for the component details. Use [Setup](../setup/index.md) for the first-install journey rather than inferring installation order from this overview.
