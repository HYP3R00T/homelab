---
icon: lucide/git-branch
---

# GitOps

This section explains how the repository turns versioned manifests into the
live homelab cluster.

## Topics

- [Repository structure](repository-structure.md): where apps,
  infrastructure, monitoring, clusters, and IaC belong
- [Reconciliation](reconciliation.md): how Flux activates layers and enforces
  dependency order
- [Adding a service](adding-a-service.md): how to use the `base/` and `lab/`
  overlay pattern

Service-specific architecture belongs under [Services](../services/index.md).
Operational commands belong under [Runbooks](../runbooks/index.md).
