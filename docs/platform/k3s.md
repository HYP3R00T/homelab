# K3s ownership

The inspected node is `ubuntu-server-02`, running K3s `v1.37.2+k3s1` on Ubuntu `26.04.1 LTS`, at `192.168.0.61`. Host installation and K3s service configuration are managed outside this repository; these manifests do not provision or reinstall the VM.

| Component | Namespace | Ownership |
| --- | --- | --- |
| CoreDNS | kube-system | K3s packaged add-on |
| Traefik | kube-system | K3s Helm controller |
| ServiceLB | kube-system | K3s embedded controller and service pods |
| Local Path Provisioner | kube-system | K3s packaged add-on |
| Metrics Server | kube-system | K3s packaged add-on |

Do not reinstall these through Flux. Kubernetes Ingress resources use the existing `traefik` class. Services of type LoadBalancer use ServiceLB; MetalLB is not required. A version-specific customization of packaged Traefik belongs in a HelmChartConfig, not a second HelmRelease.

## Inspect the foundation

```shell
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl get service traefik -n kube-system
kubectl get storageclass
kubectl top nodes
kubectl top pods -A
```

The default `local-path` class remains untouched. GitOps adds a separate non-default `local-path-retain` class using the same provisioner. It changes reclamation policy, not the storage controller or the host path.

[K3s packaged components](https://docs.k3s.io/installation/packaged-components), [networking](https://docs.k3s.io/networking/networking-services), and [storage](https://docs.k3s.io/add-ons/storage) describe the underlying behavior.
