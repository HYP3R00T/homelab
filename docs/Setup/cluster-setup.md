---
title: Cluster Setup
---

To create a single node cluster, we can use K3s. K3s is a lightweight Kubernetes distribution which makes it perfect for homelab. The official guide on installing K3s is really straight-forward. One can simply run the following command.

```bash
curl -sfL https://get.k3s.io | sh -
```

This will be enough for most people but not me. For that, I need to explain my server partition and volume.

```text
lsblk -o NAME,SIZE,TYPE
NAME                SIZE TYPE
nvme0n1           476.9G disk
├─nvme0n1p1           1G part
└─nvme0n1p2       475.9G part
  └─quasar        475.9G crypt
    ├─quasar-swap    16G lvm
    ├─quasar-root    32G lvm
    ├─quasar-home   200G lvm
    └─quasar-data   200G lvm
```

There are two partitions within my SSD. One partition is reserved for the `/boot` and the rest is for the `/root`, `/home` and `/data` mounts.

The Arch wiki suggests that 15-20 GiB should be sufficient for the `/root` volume. So, after creating that, I have distributed the rest into two separate volumes. I created `/data` directory to store data. I want to use this path to store all persistent volumes of my K3s cluster.

Therefore, I decided to modify it by adjusting the flag when I first installed K3s.

```bash
sudo mkdir -p /data/k3s-volumes
sudo chown -R root:root /data/k3s-volumes
curl -sfL https://get.k3s.io | sh -s - --default-local-storage-path /data/k3s-volumes
```
