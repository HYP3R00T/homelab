---
icon: lucide/server
---

# Install K3s

K3s provides the Kubernetes baseline on the Ubuntu VM. Host installation is managed outside this repository. Use the [official quick-start](https://docs.k3s.io/quick-start) and [installation requirements](https://docs.k3s.io/installation/requirements) for the installation procedure and your chosen version; do not run an installer on an existing cluster merely to follow this guide.

## Choices this repository expects

Keep the packaged CoreDNS, Traefik, ServiceLB, Local Path Provisioner, and Metrics Server enabled. This GitOps tree does not install replacements. Keep the default `local-path` StorageClass available; Flux adds a separate retained class using the same provisioner.

The reference design is one server node with K3s's default single-node datastore, not an embedded-etcd HA deployment. There is no NVIDIA GPU requirement. VM provisioning, host package management, and Kubernetes upgrades remain operator tasks.

## Connect from the workstation

K3s writes the administrative kubeconfig to `/etc/rancher/k3s/k3s.yaml` on the server. Follow [K3s cluster access](https://docs.k3s.io/cluster-access) to copy it securely and set its server address to a node address reachable from the workstation. Keep it private; it grants cluster administration. Use the matching TLS configuration rather than disabling certificate verification.

Verify the selected context and baseline:

```shell
kubectl config current-context
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl get service traefik -n kube-system
kubectl get storageclass
kubectl top nodes
```

Expect a Ready node, healthy packaged components, a Traefik LoadBalancer service, the default storage class, and live CPU/memory readings. Resolve baseline failures before bootstrapping workloads. Metrics Server may need a little time to collect its first readings.

See [platform architecture](../architecture/platform.md) for ownership and [K3s packaged components](https://docs.k3s.io/installation/packaged-components) for customization. Continue with [Flux bootstrap](flux.md).

## Ubuntu AppArmor signal workaround

On affected Ubuntu 26.04 kernels, containerd's AppArmor profile can reject signals between processes inside the same container. CNPG-managed PostgreSQL can then fail recovery with `could not signal for checkpoint: Permission denied`, preventing dependent applications from starting. This is a host runtime problem, not a missing storage directory or Vault credential. See [containerd issue 14485](https://github.com/containerd/containerd/issues/14485) and [the upstream correction](https://github.com/containerd/containerd/pull/14487).

Use this workaround only after confirming the signal-denial symptom. The supplied `scripts/fix-containerd-apparmor.sh` targets the rootful Ubuntu K3s server with containerd 2.3.7. Its base profile matches both upstream containerd `v2.3.7` and K3s's `v2.3.7-k3s1`; it adds the upstream rules for the exact stacked peer label. It keeps the existing confinement rules and does not change the host sysctl or make pods privileged.

Copy the script from the workstation checkout, substituting the SSH username and current node address:

```shell
scp scripts/fix-containerd-apparmor.sh <SSH_USER>@<K3S_NODE_IP>:/tmp/fix-containerd-apparmor.sh
```

SSH into that server and run:

```shell
sudo bash /tmp/fix-containerd-apparmor.sh --install
```

The script checks prerequisites and parses the generated profile before installing it. It refuses to overwrite an unmanaged profile or its own systemd drop-in path. It writes `/etc/apparmor.d/cri-containerd.apparmor.d`, loads it immediately, and adds a K3s service pre-start command so the corrected profile loads before the runtime on future starts. K3s is not restarted by this procedure.

Use the affected application's namespace and database name to check recovery after the profile is loaded. The original workload used to diagnose this issue has been removed; do not recreate it merely to repeat the check.

### What happened in this lab

On 2026-11-19, the Ubuntu node ran kernel `7.0.0-43-generic`, K3s `v1.37.2+k3s1`, and containerd `2.3.7-k3s1`. Vault authentication and secret synchronization were healthy and storage claims were bound, but PostgreSQL failed recovery with `could not signal for checkpoint: Permission denied`.

The affected containers carried the label `cri-containerd.apparmor.d//&unconfined`, with `kernel.apparmor_restrict_unprivileged_unconfined=1`. A disposable child-process signal test reproduced the restriction independently of PostgreSQL. The profile was loaded in the kernel but had no file under `/etc/apparmor.d/`.

The operator installed the correction script, which persisted and reloaded the profile without restarting K3s. The signal test then passed and the PostgreSQL primary recovered. These observations verified the host correction, separately from the application's later memory pressure. Keep the correction until a planned runtime upgrade includes the upstream fix.

If API requests begin timing out during application startup, inspect the VM directly over SSH before attributing the failure to a specific resource or rerunning bootstrap:

```shell
free -h
uptime
vmstat 1 3
```

Compare memory, swap, CPU, and I/O wait with the workload startup time. API timeouts alone do not prove memory exhaustion. Preserve the existing data volumes while investigating.

During this incident, the host subsequently reported about 1.8 GiB of occupied swap, active swap-in of 9–11 MiB/s, 39% I/O wait, and 20–36 blocked tasks in the interval samples. The one-minute load average was about 29 on four vCPUs. This confirmed heavy I/O contention with active paging, but did not identify the responsible workload or prove an OOM kill. About 1.3 GiB of memory was still reported available; low free memory alone was not the diagnosis.

When the API is too slow to return pod metrics, collect local runtime and process measurements through the existing SSH session. These commands do not require a working API server:

```shell
sudo k3s crictl stats
ps -eo pid,comm,rss,pcpu,stat --sort=-rss | head -20
cat /proc/pressure/memory /proc/pressure/io
sudo journalctl -k --since '-15 min' --grep 'oom-kill|Out of memory|Killed process' --no-pager
```

Use the results to identify which workloads need adjustment. Lowering a memory limit does not make an application's working set smaller, and increasing swap does not establish that the VM can run the complete stack comfortably.

This is a persistent temporary workaround. When planning an upgrade to a K3s release containing the upstream fix, review removal of both the managed profile and `/etc/systemd/system/k3s.service.d/20-apparmor-stacked-peer.conf`; otherwise the custom profile continues to override the runtime's generated default. Keep the profile in place until the replacement and restart procedure is ready.
