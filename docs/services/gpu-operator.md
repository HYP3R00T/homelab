---
icon: lucide/cpu
---

# NVIDIA GPU Operator

The NVIDIA GPU Operator enables the node GPU for Kubernetes workloads. It
installs discovery, validation, metrics, and device-plugin components.

## Current implementation

| Property | Value |
|---|---|
| Status | Active |
| Operator version | `v26.3.3` |
| Namespace | `gpu-operator` |
| Node count | 1 |
| Metrics endpoint | DCGM exporter on port `9400` |
| GitOps path | `gitops/infrastructure/controllers` |

Active components include Node Feature Discovery, GPU Feature Discovery, the
NVIDIA device plugin, DCGM exporter, and operator validation.

## GitOps ownership

Flux installs the Helm release from
`gitops/infrastructure/controllers/base/gpu-operator`, with the Talos-specific
values in `gitops/infrastructure/controllers/lab/gpu-operator`.

The chart is pinned to `v26.3.3`. Driver and toolkit installation remain
disabled because Talos provides both at the host layer, and
`hostPaths.driverInstallDir` remains `/usr/local`.

The host preparation is part of the initial Talos installation and is
documented in [NVIDIA GPU on Talos](../platform/nvidia-gpu.md). Talos owns the
NVIDIA kernel modules and container toolkit; the operator owns Kubernetes
discovery, validation, metrics, and the device plugin.
