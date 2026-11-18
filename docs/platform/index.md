# Platform

The homelab runs K3s on a single Ubuntu VM, with 4 vCPUs and approximately 5.28 GiB RAM. K3s owns the control plane and its packaged networking, DNS, storage provisioner, and Metrics Server.

Read [K3s ownership](k3s.md) before changing platform components and [local storage](../services/local-path-provisioner.md) before changing claims. The previous Talos and NVIDIA setup is available through Git history rather than maintained as an alternative deployment tree.
