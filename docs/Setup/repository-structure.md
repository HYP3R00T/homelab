---
title: Repository Structure
---

```text
tree
.
├── apps                    # Application manifests and overlays
│   ├── base                # Base manifests for reusable app configurations
│   │   ├── linkding        # Base configuration for Linkding app
│   │   └── mealie          # Base configuration for Mealie app
│   └── lab                 # Lab-specific overlays for applications
│       ├── kustomization.yaml
│       ├── linkding        # Lab-specific Linkding overlay
│       └── mealie          # Lab-specific Mealie overlay
├── cluster                 # Cluster-wide configuration and resources
│   └── lab                 # Lab environment cluster configs
│       ├── apps.yaml       # Application references for the lab cluster
│       ├── flux-system     # Flux CD configuration for GitOps
│       │   ├── gotk-components.yaml
│       │   ├── gotk-sync.yaml
│       │   └── kustomization.yaml
│       └── monitoring.yaml # Monitoring stack reference for the lab cluster
└── monitoring              # Monitoring stack configuration
    ├── configs             # Custom configuration files for monitoring tools
    └── controllers         # Kustomize controllers for monitoring deployments
        ├── base            # Base manifests for monitoring stack (e.g., kube-prometheus-stack)
        │   └── kube-prometheus-stack
        └── lab             # Lab-specific overlays for monitoring stack
            ├── kube-prometheus-stack
            └── kustomization.yaml
```

This repository structure is based on the recommended layout from the FluxCD documentation. Separating `apps` and `monitoring` allows for clear distinction between application workloads and cluster-level operational tooling or observability stacks. This modular approach makes it easy to scale, maintain, and customize different parts of my infrastructure independently. By isolating monitoring and controllers, you can manage and update my observability stack without impacting application deployments, and vice versa. This structure also supports GitOps best practices, enabling flexible overlays, environment-specific customizations, and easier onboarding as my homelab grows.
