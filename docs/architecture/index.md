---
icon: lucide/network
---

# Architecture

This section explains relationships that span multiple GitOps layers or
services. The manifests remain the operational source of truth; these pages
provide a readable model of how the pieces work together.

## Topics

- [Platform architecture](platform.md): the node, GitOps layers, applications,
  and shared services
- [Traffic flow](traffic-flow.md): local ingress and public Cloudflare routing
- [Secrets flow](secrets-flow.md): how Vault, External Secrets, Kubernetes, and
  Cloudflared exchange credentials

Use the [Services](../services/index.md) section for component-level reference
and [Runbooks](../runbooks/index.md) for executable procedures.
