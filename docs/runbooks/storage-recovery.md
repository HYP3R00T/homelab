# Recover retained storage

New Vault and monitoring volumes use the non-default local-path-retain StorageClass. K3s's existing local provisioner creates the PV directories. Retain preserves data after claim deletion; manual recovery and cleanup are deliberate operator steps.

## Record where data lives

```shell
kubectl get pvc -A -o wide
kubectl get pv -o custom-columns=NAME:.metadata.name,NAMESPACE:.spec.claimRef.namespace,CLAIM:.spec.claimRef.name,POLICY:.spec.persistentVolumeReclaimPolicy,HOSTPATH:.spec.hostPath.path,LOCAL:.spec.local.path
kubectl get configmap local-path-config -n kube-system -o jsonpath='{.data.config\.json}'
```

Save the PV and PVC YAML securely alongside backups, including claim names, exact directories, access modes, node affinity, storage classes, ownership, and permissions. These objects can contain infrastructure details; keep them out of the public documentation site. The inspected host root is /var/lib/rancher/k3s/storage. Inspect the actual directory over SSH with sudo as needed; do not edit live database files.

## Pod replacement

A replacement pod mounts the existing claim. The StatefulSets for Prometheus, Grafana, and Alertmanager explicitly retain claims on deletion and scale-down, and their dynamically created PVs inherit Retain. Existing data is not discarded just because a pod exits. Confirm the bound PV's policy rather than assuming the class changed an already-created volume.

Linkding's pre-existing default-class volume is outside this new storage policy. Its claim is preserved unchanged and must not be deleted. Changing a StorageClass does not change existing PV reclaim policies.

## Released volume

If a monitoring claim is explicitly deleted, its PV becomes Released and its directory remains. Stop reconciliation of the affected consumer while planning recovery. Record the old PV and its claim reference. An administrator must clear the obsolete claim binding when safe, create a matching claim explicitly bound to the retained PV, and use that claim with the workload's expected name. Recreating the old PVC name alone can allocate a fresh empty directory instead of recovering the retained data.

Do not remove files or reformat a volume to make it bind. Check node affinity, namespace, claim name, capacity, access mode, and StorageClass before making it available to the workload. Use an isolated recovery test before applying a rebinding procedure to important data.

## Back up before rebuilding K3s

The K3s uninstall script deletes Local Storage Persistent Volume data. Retain is a Kubernetes reclamation policy, not protection from host scripts, manual deletion, or VM disk loss. Do not run uninstall and expect these directories to survive.

Use application-consistent exports or a coordinated offline VM backup. For an offline backup, shut down the VM cleanly, back up its disk through the hypervisor to separate storage, and verify restoration on an isolated VM before relying on the copy. A snapshot on the same failing disk is not an independent backup. Keep configuration, PV/PVC metadata, filesystem ownership, Vault recovery material, and required decryption keys with the recovery plan. Vault Raft snapshots require the matching unseal/recovery material; see [Vault recovery](vault-recovery.md).

Backup tooling and schedules are not automated by this cleanup. Perform and verify the chosen backup before any reinstall. After a fresh cluster, restore the directories or application snapshots and explicitly reconstruct PVs, claims, and node affinity. Kubernetes does not scan old directories and automatically recreate their volume objects.

## Retention versus backup

Prometheus still expires data at 10 days or its 8GB retention-size boundary. Retain does not disable that database cleanup. Alertmanager keeps silence/notification state, not metric history. Grafana keeps its database and local state; dashboards provisioned from Git/Helm can be recreated from configuration.

Only manually remove a retained directory after identifying its former owner and confirming its backup and data are no longer needed. No cleanup script in this repository removes retained data automatically.

References: [Kubernetes PV lifecycle](https://kubernetes.io/docs/concepts/storage/persistent-volumes/), [K3s storage](https://docs.k3s.io/add-ons/storage), [K3s uninstall](https://docs.k3s.io/installation/uninstall).
