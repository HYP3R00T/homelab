---
icon: lucide/hard-drive
---

# Local Path Provisioner

K3s runs Rancher's Local Path Provisioner in `kube-system`. This repository does not install another provisioner or change its existing configuration.

| Class | Provisioner | Reclaim policy | Use |
| --- | --- | --- | --- |
| local-path | rancher.io/local-path | Existing K3s default, inspected as Delete | Existing Linkding claim remains unchanged |
| local-path-retain | rancher.io/local-path | Retain | Vault and Shoutrrr claims |

The additional class is non-default and defined in `gitops/infrastructure/core/storage-class.yaml`. Both use WaitForFirstConsumer; each new claim gets a dynamically created PV. There is no duplicate controller and no need for one static PV YAML file per application.

The default K3s storage root used by this deployment is `/var/lib/rancher/k3s/storage`. Each PV points at a directory and has node affinity. Inspect actual paths before backing up or recovering data. Requested capacities do not enforce a directory quota; watch free disk space on the VM.

## Verification

No account or separate provisioner installation is required. Verify the K3s provisioner and the additional class after core reconciliation:

```shell
kubectl get storageclass
kubectl get pvc -A
kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,NAMESPACE:.spec.claimRef.namespace,POLICY:.spec.persistentVolumeReclaimPolicy,HOSTPATH:.spec.hostPath.path,LOCAL:.spec.local.path
```

Retain keeps the data after explicit claim deletion, but a released PV needs manual rebinding. It does not make a backup or protect storage from host deletion, VM disk failure, or K3s uninstall. Read [storage recovery](../runbooks/storage-recovery.md) before rebuilding the cluster.

See [K3s storage](https://docs.k3s.io/add-ons/storage) for the packaged provisioner and [Kubernetes persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for claim lifecycle.
