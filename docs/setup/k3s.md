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

On affected Ubuntu 26.04 kernels, containerd's AppArmor profile can reject signals between processes inside the same container. CNPG-managed PostgreSQL can then fail recovery with `could not signal for checkpoint: Permission denied`, preventing Postiz from starting. This is a host runtime problem, not a missing storage directory or Vault credential. See [containerd issue 14485](https://github.com/containerd/containerd/issues/14485) and [the upstream correction](https://github.com/containerd/containerd/pull/14487).

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

From the workstation, verify recovery and the application dependencies:

```shell
kubectl -n postiz wait --for=condition=Ready cluster/postiz-postgres --timeout=180s
kubectl -n postiz get cluster,database,pods
kubectl -n postiz rollout status deployment/postiz-temporal --timeout=180s
kubectl -n postiz rollout status deployment/postiz --timeout=180s
```

Existing containers receive the reloaded policy; Kubernetes retries failed containers automatically. If PostgreSQL becomes ready but another component remains unhealthy, inspect its current logs and events instead of recreating volumes. A successful database recovery does not prove that all application startup steps have finished.

### What happened in this lab

On 2026-11-19, the Ubuntu node ran kernel `7.0.0-43-generic`, K3s `v1.37.2+k3s1`, and containerd `2.3.7-k3s1`. Vault authentication and application secret synchronization were healthy, and all Postiz storage claims were bound. However, PostgreSQL repeatedly failed recovery with `could not signal for checkpoint: Permission denied`. Postiz could not reach its database, and Temporal could not finish setup.

The affected containers carried the AppArmor label `cri-containerd.apparmor.d//&unconfined`, with `kernel.apparmor_restrict_unprivileged_unconfined=1`. A disposable child-process test also failed to receive a signal, independently reproducing the host restriction outside PostgreSQL. Increasing memory, creating directories manually, or rerunning Terraform would not resolve that restriction.

The profile file did not exist under `/etc/apparmor.d/`; containerd had loaded its generated profile into the kernel. The operator installed the supplied correction script on the server. It created the persistent profile and service drop-in and reloaded the profile without restarting K3s. Afterward, the same signal test passed, CNPG reported a healthy PostgreSQL primary, and both `temporal` and `temporal_visibility` database resources reported applied.

Restarting Temporal cleared its earlier startup attempt; its server became ready and registered the default namespace. Postiz subsequently reached frontend and backend startup, but its full rollout was not confirmed before Kubernetes API requests began timing out. These results verify the AppArmor correction and database recovery, not end-to-end application health or publishing.

Use this workstation command to repeat the disposable signal check; it never signals Redis itself. A successful test prints `allowed`. The shell may also print `User defined signal 1` when the disposable sleep exits, which is expected:

```shell
kubectl -n postiz exec deployment/postiz-redis -- sh -c '
  sleep 2 & child=$!
  if kill -USR1 "$child"; then echo allowed; else echo denied; fi
  wait "$child"
  exit 0
'
```

If Postiz or Temporal remains stuck in an earlier startup attempt after the database is ready, restart those Deployments and verify them again. This replaces their pods and preserves the database, Redis, and upload volumes:

```shell
kubectl -n postiz rollout restart deployment/postiz-temporal deployment/postiz
kubectl -n postiz rollout status deployment/postiz-temporal --timeout=180s
kubectl -n postiz rollout status deployment/postiz --timeout=180s
kubectl -n flux-system get kustomizations postiz
```

Pod restart counts from before the correction remain visible. Check readiness and whether the counts continue increasing rather than treating historical counts as a new failure. Browser sign-in and social publishing still require application-level verification after a healthy rollout.

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
