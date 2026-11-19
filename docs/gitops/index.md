---
icon: lucide/git-branch
---

# GitOps

GitOps makes the deployment configuration reviewable: changes reach `main`, Flux reads the cluster entrypoint, and each group reconciles its owned resources. Readiness boundaries keep operators, secret delivery, and their consumers in the necessary order.

| Topic | What it explains |
| --- | --- |
| [Repository structure](repository-structure.md) | Applications, Infrastructure, cluster entrypoints, and resource files |
| [Reconciliation](reconciliation.md) | Included groups, dependencies, and how to diagnose a waiting rollout |
| [Add a component](adding-a-service.md) | Placement, resource naming, activation, and documentation |

A directory in Git is not activation, and a successful Git push is not proof that a workload is running. [Setup](../setup/index.md) explains first bootstrap; [Runbooks](../runbooks/index.md) cover rollout and recovery. Component behavior belongs to [Applications](../apps/index.md) or [Infrastructure](../infrastructure/index.md).
