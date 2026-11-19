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
