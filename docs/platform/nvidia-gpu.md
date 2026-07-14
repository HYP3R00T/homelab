---
icon: lucide/cpu
---

# NVIDIA GPU on Talos

GPU support has two ownership layers. Talos supplies the signed kernel modules
and container toolkit in its immutable image. Flux installs NVIDIA GPU
Operator components that discover the device and expose it to Kubernetes.

## Prepare the host during installation

The Talos Image Factory schematic contains:

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/nvidia-container-toolkit-production
      - siderolabs/nvidia-open-gpu-kernel-modules-production
```

The installed image uses the same schematic and Talos version:

```text
factory.talos.dev/metal-installer/6698d6f136c5bb37ca8bb8482c9084305084da0a5ead1f4dcae760796f8ab3a2:v1.13.6
```

The initial `controlplane.yaml` also declares the required modules:

```yaml
machine:
  kernel:
    modules:
      - name: nvidia
      - name: nvidia_uvm
      - name: nvidia_drm
      - name: nvidia_modeset
```

These settings were applied as part of the fresh installation, together with
the single-node scheduling and storage configuration. No post-install Talos
upgrade or machine patch is required. See [Talos Linux](talos-linux.md) for the
complete procedure.

## Verify the Talos layer

Check the installed extensions:

```shell
talosctl get extensions
```

The expected names are:

```text
nvidia-container-toolkit-production
nvidia-open-gpu-kernel-modules-production
schematic
modules.dep
```

The `schematic` entry must report:

```text
6698d6f136c5bb37ca8bb8482c9084305084da0a5ead1f4dcae760796f8ab3a2
```

Check the live kernel modules:

```shell
talosctl get modules | grep nvidia
```

The module list must include `nvidia`, `nvidia_uvm`, `nvidia_drm`, and
`nvidia_modeset`. Do not continue to the operator layer if either the
extensions or modules are absent.

## Install the Kubernetes layer through Flux

The GPU Operator Helm release is declared under:

```text
gitops/infrastructure/controllers/base/gpu-operator
gitops/infrastructure/controllers/lab/gpu-operator
```

The lab overlay configures the ownership boundary:

```yaml
driver:
  enabled: false

toolkit:
  enabled: false

hostPaths:
  driverInstallDir: /usr/local
```

Driver and toolkit installation are disabled because Talos already owns them.
The operator supplies Node Feature Discovery, GPU Feature Discovery, the
device plugin, validation, and DCGM metrics.

Flux activates the release through the `infrastructure-controllers`
Kustomization. Verify reconciliation and the namespace workloads:

```shell
flux get kustomization infrastructure-controllers
flux get helmrelease gpu-operator --namespace gpu-operator
kubectl get pods --namespace gpu-operator
```

The CUDA validator may remain as a completed pod. The operator, discovery,
device-plugin, validator, and DCGM exporter workloads should otherwise be
running and ready.

## Verify Kubernetes GPU capacity

```shell
kubectl get nodes -o json | \
  jq '.items[] | {
    name: .metadata.name,
    gpus: .status.allocatable["nvidia.com/gpu"]
  }'
```

The current node advertises one `nvidia.com/gpu` resource. The GPU labels added
by discovery can be inspected with:

```shell
kubectl get node --show-labels | tr ',' '\n' | grep nvidia.com
```

## Run an end-to-end CUDA test

Resource advertisement proves discovery; a CUDA workload proves scheduling,
runtime injection, device access, and execution together:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
  restartPolicy: OnFailure
  containers:
    - name: cuda-vectoradd
      image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda12.5.0-ubuntu22.04
      resources:
        limits:
          nvidia.com/gpu: 1
```

Apply the pod and inspect its output:

```shell
kubectl apply -f cuda-vectoradd.yaml
kubectl logs pod/cuda-vectoradd
```

A successful run ends with:

```text
Test PASSED
Done
```

Remove the validation pod afterward:

```shell
kubectl delete -f cuda-vectoradd.yaml
```

## Upgrade rule

Future Talos upgrades must use an Image Factory installer that contains the
same NVIDIA extensions for the target Talos release. Upgrading with the default
installer would remove the host capabilities even though the GPU Operator
manifests remain present in Kubernetes.

## References

- [NVIDIA GPU support on Talos](https://docs.siderolabs.com/talos/v1.13/configure-your-talos-cluster/hardware-and-drivers/nvidia-gpu)
- [Talos Image Factory](https://factory.talos.dev/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html)
