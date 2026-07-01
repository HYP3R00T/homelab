---
icon: lucide/folders
---

# Repository Structure

This repository is grouped by role. The goal is to keep it easy to understand what supports the platform, what users actually consume, and what observes the whole system.

## At a glance

```text
.
├── apps/            # User-facing workloads
├── infrastructure/  # Platform services that support the cluster
├── monitoring/      # Observability and inspection layer
└── clusters/        # Flux entrypoints that activate things in a cluster
```

At the simplest level, `apps/` is for things people use, `infrastructure/` is for the shared capabilities those apps need, `monitoring/` is for observing both layers, and `clusters/` is for deciding what actually goes live.

## Apps

`apps/` is for services that are the actual destination.

These are the things a user opens, signs into, and actively uses. They are built on top of the shared capabilities provided by `infrastructure/`.

Examples:

- Homepage
- Linkding
- Mealie

!!! tip "Ask yourself"
    Is this something I or another person would actively use?
    If it disappeared, would a human notice before the platform noticed?
    Is this the destination rather than the plumbing?

If the answer is mostly yes, it belongs in `apps/`.

## Infrastructure

`infrastructure/` is for services that support the cluster or support other services.

This is the base layer that applications depend on. These services usually do not exist for their own sake. They exist so applications can receive traffic, use certificates, store secrets, reach databases, or be exposed externally when needed.

Examples:

- Traefik
- MetalLB
- Cloudflared
- Vault
- External Secrets Operator
- CloudNativePG

In this repository, infrastructure means shared capabilities such as:

- ingress and routing
- load balancing
- certificate management
- secret storage and secret delivery
- database services
- controlled external exposure

If multiple applications would rely on it as a common platform feature, it belongs in `infrastructure/`.

## Monitoring

`monitoring/` is for observability.

Monitoring is separate because it observes both `infrastructure/` and `apps/`. Its job is to tell us what is happening across the system, not to serve end users directly and not to provide platform capabilities.

Examples:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node exporters

If its primary job is to measure, record, alert, or explain what is happening in the system, it belongs in `monitoring/`.

Keep `monitoring/` as a separate top-level folder. It has a different responsibility from infrastructure: infrastructure enables workloads, while monitoring observes infrastructure and applications together.

## What `clusters/` does

`clusters/` is the activation layer.

This folder does not define the services themselves. It tells Flux which parts of the repository should be applied to a given cluster.

That means a manifest can exist in the repository without being live in the cluster yet.

!!! warning "Important distinction"
    A service can be present in the repo but absent from the cluster.
    The folder tells us what the service is for.
    The cluster wiring tells us whether it is currently active.

This is why commented entries in a `kustomization.yaml` matter so much. The files may exist, but the cluster will not reconcile them until the cluster wiring includes them.

For simple layers, a cluster entrypoint can target the whole overlay such as `./apps/lab` or `./monitoring/lab`.

For infrastructure services that need stricter ordering, the cluster entrypoint can hand off to an internal infrastructure Flux layer. In this repository, `clusters/lab/infrastructure.yaml` points to `infrastructure/lab/flux`, and that folder contains the service-by-service `dependsOn` chain for `vault`, `external-secrets`, `cloudflared`, and `metallb-config`.

## Applying this to services in the repository

- `apps/`: `Homepage`, `Linkding`
- `infrastructure/`: `Traefik`, `MetalLB`, `Vault`, `External Secrets Operator`, `Cloudflared`
- `monitoring/`: `Prometheus`, `Grafana`

!!! note "Staged vs active"
    A service can belong to one of these folders even when it is not currently enabled.

    In this repository, `Vault`, `External Secrets Operator`, `Cloudflared`, `CloudNativePG`, and the monitoring stack are staged or partially wired work, while `homepage`, `linkding`, `metallb`, and `traefik` represent the established active path.

## Working principle going forward

Before adding a new service, answer one question first: what role does this service play in the homelab?

If it is a shared capability, it belongs in `infrastructure/`.
If it is something people use directly, it belongs in `apps/`.
If it watches the whole system, it belongs in `monitoring/`.
