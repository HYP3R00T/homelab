---
icon: lucide/folder-cog
---

# Local Path Provisioner

Local Path Provisioner supplies dynamic local PersistentVolumes for workloads
that request the `local-path` StorageClass.

## Current implementation

| Property | Value |
|---|---|
| Version | `v0.0.36` |
| Namespace | `local-path-storage` |
| StorageClass | `local-path` (default) |
| Binding mode | `WaitForFirstConsumer` |
| Reclaim policy | `Retain` |
| Host root | `/var/mnt/local-path-provisioner` |

The upstream resources are vendored in
`gitops/infrastructure/controllers/base/local-path-provisioner`. The lab overlay
owns the Talos path, namespace policy, default-class annotation, and reclaim
policy.

The controller has explicit resource requests and limits. Its short-lived
helper pod also has a resource envelope, avoiding unbounded scheduling and
noisy-neighbor warnings.

## Talos dependency

The provisioner assumes the host mount already exists. Talos creates and
manages it as a dedicated XFS partition through `UserVolumeConfig`; Flux does
not manage that machine configuration.

The volume was defined in `controlplane.yaml` as part of the original Talos
installation, not added later. See
[Configure the control plane](../platform/talos-linux.md#configure-the-control-plane)
for the exact machine-configuration diff that was applied.

Verify the host volume before troubleshooting the Kubernetes provisioner:

```shell
talosctl get volumestatus u-local-path-provisioner
talosctl get mountstatus u-local-path-provisioner
talosctl ls /var/mnt/local-path-provisioner
```

The XFS filesystem is mounted at `/var/mnt/local-path-provisioner`. The current
node reports `EPHEMERAL` on `/dev/nvme0n1p4` and the user volume on
`/dev/nvme0n1p5`.

## Data lifecycle

Each dynamically provisioned volume becomes a directory beneath the configured
root. The PV includes node affinity, keeping the consuming pod on the node that
contains its data.

Vault and Linkding request this StorageClass directly. Dynamic provisioning
avoids static PV manifests that embed a generated Talos hostname and become
unschedulable after a reinstall changes the node identity.

`Retain` is chosen for safety. Deleting a PVC leaves its PV and directory for
manual recovery or cleanup. Operators must verify that data is no longer needed
before removing retained directories.

The requested PVC size is not an enforced filesystem quota. Monitor the free
space on `/var/mnt/local-path-provisioner` independently of Kubernetes PVC
capacity. A workload can fill the shared user volume and affect other workloads
using it, although it cannot consume the separate `EPHEMERAL` filesystem.

Data survives pod restarts, node reboots, and normal Talos upgrades. It does
not survive an NVMe failure or a reinstall that wipes and repartitions the
disk. Local persistent storage is not a backup; important data needs an
off-volume backup.

Verify the Kubernetes side of the storage chain with:

```shell
kubectl get storageclass local-path
kubectl get pvc --all-namespaces
kubectl get pv
kubectl get pods --namespace local-path-storage
```

## References

- [Talos user volumes](https://docs.siderolabs.com/talos/v1.13/configure-your-talos-cluster/storage-and-disk-management/disk-management/user)
- [Rancher Local Path Provisioner](https://github.com/rancher/local-path-provisioner)
