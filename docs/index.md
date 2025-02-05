---
title: Homelab
description: Documenting my homelab journey, lessons learned, and experiments in self-hosting and networking.
hide:
    - navigation
---

```yaml
homelab:
  hardware:
    device: "HP Notebook - 15-ay563tu"
    processor: "Intel i3-6006U (4) @ 2.000GHz"
    ram: "4GB"
    storage: "1TB HDD"
    virtualization: "Docker"
  system:
    os: "Ubuntu Server 24.04.1 LTS"
  kubernetes:
    distribution: "k3s"
    git_ops: "FluxCD"
    setup: "Single-node cluster"
    tools:
      - "Traefik for ingress management"
      - "FluxCD for continuous delivery"
    network:
      ingress: "Local, not exposed to the internet"
  services:
    - name: "Linkding"
      purpose: "Bookmark management"
```
