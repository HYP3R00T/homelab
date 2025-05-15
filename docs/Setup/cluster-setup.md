---
title: Cluster Setup
---

To create a single node cluster, we can use K3s. K3s is a lightweight Kubernetes distribution which makes it perfect for homelab. The official guide on installing K3s is really straight-forward. One can simply run the following command.

```bash
curl -sfL https://get.k3s.io | sh -
```

This will be enough for most people but not me. For that, I need to explain my server partition and volume quickly.

```text
lsblk -o NAME,SIZE,TYPE
NAME                          SIZE TYPE
nvme0n1                     476.9G disk
├─nvme0n1p1                     1G part
├─nvme0n1p2                     2G part
└─nvme0n1p3                 473.9G part
  └─dm_crypt-0              473.9G crypt
    ├─ubuntu--vg-ubuntu--lv   100G lvm
    ├─ubuntu--vg-data         200G lvm
    └─ubuntu--vg-home         150G lvm
```

I created `/data` directory to store data. I want to use this path to store all persistent volumes of my K3s cluster.

Therefore, I decided to modify it by adjusting the flag when I first installed K3s.

```bash
sudo mkdir -p /data/k3s-volumes
sudo chown -R root:root /data/k3s-volumes
curl -sfL https://get.k3s.io | sh -s - --default-local-storage-path /data/k3s-volumes
```
