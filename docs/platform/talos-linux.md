---
icon: lucide/server
---

# Talos Linux

Talos Linux `v1.13.6` runs the single Kubernetes control-plane and workload
node. The installation was prepared as one complete machine configuration:
the custom NVIDIA image, kernel modules, control-plane scheduling, and disk
layout were all present before the first apply.

## Build the installation image

The AMD64 bare-metal image was created with Talos Image Factory using this
schematic:

```text
6698d6f136c5bb37ca8bb8482c9084305084da0a5ead1f4dcae760796f8ab3a2
```

It contains only the two NVIDIA extensions required by this machine:

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/nvidia-container-toolkit-production
      - siderolabs/nvidia-open-gpu-kernel-modules-production
```

All other Image Factory settings used their defaults. The same schematic and
Talos version must be used by `machine.install.image`; booting a custom ISO but
installing the default image would omit the extensions from the installed
system.

## Install the CLI

The workstation uses mise to manage `talosctl`:

```shell
mise use -g talosctl@latest
talosctl version --client
```

The CLI resolved to `v1.13.6` for this installation. Keeping the client and
target Talos versions aligned avoids version-skew warnings while applying the
machine configuration.

## Inspect the installation disks

Boot the Image Factory ISO and wait for Talos maintenance mode. Export the
node address and inspect the available disks over the insecure maintenance API:

```shell
export CONTROL_PLANE_IP=192.168.0.50

talosctl get disks \
  --insecure \
  --nodes "$CONTROL_PLANE_IP"
```

The machine exposes two relevant devices:

| Device | Size | Transport | Purpose |
|---|---:|---|---|
| `nvme0n1` | 256 GB | NVMe | Talos system and workload storage |
| `sda` | 62 GB | USB | Bootable installation media |

The NVMe serial observed during installation was `2401VC2S03904597`. Always
inspect the live disks instead of assuming device names before a destructive
installation.

## Generate the cluster configuration

```shell
export CLUSTER_NAME=homelab
export DISK_NAME=nvme0n1

talosctl gen config \
  "$CLUSTER_NAME" \
  "https://${CONTROL_PLANE_IP}:6443" \
  --install-disk "/dev/${DISK_NAME}"
```

The command creates:

```text
controlplane.yaml
talosconfig
worker.yaml
```

All three files contain cluster configuration, but `talosconfig` is
particularly important for recovery: Kubernetes credentials do not grant
administrative access to the Talos API. Keep the generated files outside Git
and back them up securely.

## Configure the control plane

Edit the generated `controlplane.yaml` once before applying it. The complete
change can be reviewed with:

```shell
git diff -- controlplane.yaml
```

This is the diff that was applied during the installation:

```diff
diff --git a/controlplane.yaml b/controlplane.yaml
index afbc1d3..7a935dc 100644
--- a/controlplane.yaml
+++ b/controlplane.yaml
@@ -75,8 +75,8 @@ machine:
     # Used to provide instructions for installations.
     install:
         disk: /dev/nvme0n1 # The disk used for installations.
-        image: ghcr.io/siderolabs/installer:v1.13.6 # Allows for supplying the image used to perform the installation.
-        wipe: false # Indicates if the installation disk should be wiped at installation time.
+        image: factory.talos.dev/metal-installer/6698d6f136c5bb37ca8bb8482c9084305084da0a5ead1f4dcae760796f8ab3a2:v1.13.6 # Allows for supplying the image used to perform the installation.
+        wipe: true # Indicates if the installation disk should be wiped at installation time.
         grubUseUKICmdline: true # Indicates if legacy GRUB bootloader should use kernel cmdline from the UKI instead of building it on the host.

         # # Look up disk using disk attributes like model, size, serial and others.
@@ -178,10 +178,14 @@ machine:
     #             machine: worker-1

     # # Configures the kernel.
-    # kernel:
+    kernel:
     #     # Kernel modules to load.
-    #     modules:
+        modules:
     #         - name: btrfs # Module name.
+          - name: nvidia
+          - name: nvidia_uvm
+          - name: nvidia_drm
+          - name: nvidia_modeset

     # # Configures the seccomp profiles for the machine.
     # seccompProfiles:
@@ -381,7 +385,7 @@ cluster:
     #     certLifetime: 1h0m0s # Admin kubeconfig certificate lifetime (default is 1 year).

     # # Allows running workload on control-plane nodes.
-    # allowSchedulingOnControlPlanes: true
+    allowSchedulingOnControlPlanes: true
 ---
 apiVersion: v1alpha1
 kind: HostnameConfig
@@ -390,3 +394,27 @@ auto: stable # A method to automatically generate a hostname for the machine.
 # # A static hostname to set for the machine.
 # hostname: controlplane1
 # hostname: controlplane1.example.org
+---
+apiVersion: v1alpha1
+kind: VolumeConfig
+name: EPHEMERAL
+provisioning:
+  diskSelector:
+    match: disk.transport == "nvme"
+  minSize: 32GiB
+  maxSize: 64GiB
+  grow: false
+---
+apiVersion: v1alpha1
+kind: UserVolumeConfig
+name: local-path-provisioner
+provisioning:
+  diskSelector:
+    match: disk.transport == "nvme"
+  minSize: 150GiB
+  maxSize: 160GiB
+  grow: false
+filesystem:
+  type: xfs
+mount:
+  disableAccessTime: true
```

The patch makes all installation-time changes together:

- Installs the Image Factory build with the NVIDIA extensions and wipes the
  selected NVMe disk.
- Loads the four NVIDIA kernel modules supplied by that image.
- Allows workloads to run on the single control-plane node.
- Caps `EPHEMERAL` at 64 GiB and creates a separate 150-160 GiB XFS user volume
  for persistent workload data.

!!! danger "The installation wipes the NVMe disk"
    `wipe: true` removes the existing Talos installation, user-volume
    partitions, and workload data on `nvme0n1`. Verify backups and the selected
    device before applying this configuration.

The 256 GB disk is approximately 238 GiB. The two volume maximums consume 224
GiB, leaving room for Talos system partitions and unallocated headroom. Because
`grow` is disabled, this layout should be decided before initial provisioning.

## Validate and apply

Validate the complete multi-document configuration before writing the disk:

```shell
talosctl validate \
  --config controlplane.yaml \
  --mode metal \
  --strict
```

The expected result is:

```text
controlplane.yaml is valid for metal mode
```

Apply it while the node is still in maintenance mode:

```shell
talosctl apply-config \
  --insecure \
  --nodes "$CONTROL_PLANE_IP" \
  --file controlplane.yaml
```

Wait for the installed system to boot from the NVMe disk before continuing.

## Bootstrap the cluster

Configure the Talos endpoint from the generated credentials:

```shell
talosctl \
  --talosconfig ./talosconfig \
  config endpoints "$CONTROL_PLANE_IP"
```

Bootstrap the single etcd member exactly once:

```shell
talosctl bootstrap \
  --nodes "$CONTROL_PLANE_IP" \
  --talosconfig ./talosconfig
```

Retrieve Kubernetes credentials:

```shell
talosctl kubeconfig \
  --nodes "$CONTROL_PLANE_IP" \
  --talosconfig ./talosconfig
```

Verify the complete control plane:

```shell
talosctl health \
  --nodes "$CONTROL_PLANE_IP" \
  --talosconfig ./talosconfig
```

The health check covers etcd consistency, the Talos API, boot completion,
kubelet, control-plane static pods, node readiness, kube-proxy, CoreDNS, and
node schedulability.

## Configure the default Talos context

The generated context has an endpoint but no default node. Set it explicitly:

```shell
talosctl \
  --talosconfig ./talosconfig \
  config node "$CONTROL_PLANE_IP"

talosctl --talosconfig ./talosconfig config info
```

Install the client configuration in its default location so future commands do
not require `--talosconfig`:

```shell
mkdir -p ~/.talos
cp ./talosconfig ~/.talos/config
talosctl config info
```

Reboot only when a configuration change requires it:

```shell
talosctl reboot
```

## Verify the installed capabilities

Confirm the node version and scheduling state:

```shell
kubectl get nodes -o wide
```

Confirm the custom extensions and loaded modules:

```shell
talosctl get extensions
talosctl get modules
```

The installed system must report the two NVIDIA extensions, the schematic ID,
and the four `nvidia*` modules. Confirm the disk layout and mount:

```shell
talosctl get volumestatus
talosctl get mountstatus u-local-path-provisioner
```

The current layout provisions `EPHEMERAL` as `/dev/nvme0n1p4` and the XFS user
volume as `/dev/nvme0n1p5`, mounted at
`/var/mnt/local-path-provisioner`.

## Ownership and recovery

Talos machine configuration remains outside this GitOps repository. Flux owns
Kubernetes resources only after the API is available. Preserve these items in
a secure backup:

- `talosconfig`, `controlplane.yaml`, and `worker.yaml`
- Vault recovery material and Raft snapshots
- application data stored outside the NVMe failure domain

A reinstall changes Kubernetes identity material, including the cluster CA and
service-account tokens. Vault Kubernetes authentication must therefore be
refreshed after a reinstall even when the API address remains `192.168.0.50`.

Continue with [NVIDIA GPU on Talos](nvidia-gpu.md) and the
[Local Path Provisioner](../services/local-path-provisioner.md) for the
Kubernetes-facing layers.

## References

- [Talos getting started](https://docs.siderolabs.com/talos/v1.13/getting-started/getting-started)
- [Talos Image Factory schematic](https://factory.talos.dev/?arch=amd64&platform=metal&schematic-id=6698d6f136c5bb37ca8bb8482c9084305084da0a5ead1f4dcae760796f8ab3a2&target=metal&version=1.13.6)
- [Talos machine configuration](https://docs.siderolabs.com/talos/v1.13/reference/configuration)
