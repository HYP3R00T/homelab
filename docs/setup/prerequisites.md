---
icon: lucide/clipboard-check
---

# Prerequisites

Use a Linux workstation to administer an Ubuntu VM reachable over your LAN. The reference VM has 4 vCPUs, approximately 5.28 GiB RAM, and a roughly 76 GiB root filesystem. Those describe this deployment, not guaranteed minimums or a recommendation to allocate the same amount to every installation.

## Prepare the workstation

1. Clone the repository and read its [architecture](../architecture/index.md) and [reconciliation model](../gitops/reconciliation.md). For your own deployment, review the FluxInstance source URL and branch before bootstrap.
2. Install Git, kubectl, Python 3, and [mise](https://mise.jdx.dev/getting-started.html). Review `mise.toml` and the repository's project-enter hook before trusting it; the hook can install development hooks and Commitizen.
3. Run `mise install` for the declared Helm, Flux, Vault, Terraform, and documentation tools. The tool declarations currently use `latest`; record the versions you use when diagnosing a reproducibility issue.
4. Obtain administrator kubeconfig access after K3s installation. Keep kubeconfig and all credentials outside Git. Confirm the context before any cluster-changing command.
5. Record the node's current LAN IP address. Arrange a stable allocation if desired through your existing network administration; this guide does not configure DHCP or DNS.

```shell
kubectl version --client
helm version
flux version --client
vault version
terraform version
```

Read [K3s requirements](https://docs.k3s.io/installation/requirements) for host, network, firewall, and port requirements. Keep the Kubernetes API private to the administration network. The hosts-file entry used for HTTP ingress does not configure the kubeconfig API address.

## Prepare for persistence

Identify independent backup storage before relying on application data. Vault initialization produces unseal shares and a root token that must be stored securely outside this repository. Terraform state and application data also need a recovery plan; Git contains neither the secret values nor the databases.

The [storage recovery guide](../runbooks/storage-recovery.md) explains the distinction between Retain and backup. Continue with [K3s](k3s.md).
