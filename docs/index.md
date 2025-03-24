---
title: Homelab
description: Documenting my homelab journey, lessons learned, and experiments in self-hosting and networking.
hide:
    - navigation
---

```yaml
homelab:
  hardware:
    device: "ASUS TUF Gaming F17"
    processor: "Intel i5-11400H (12) @ 4.500GHz"
    ram: "16GB"
    storage: "512GB SSD"
    gpu: "Nvidia RTX 3050"
    vram: "4GB"
    virtualization: "Docker"
  system:
    os: "Arch Linux x86_64"
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
