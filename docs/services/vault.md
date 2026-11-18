# Vault

Vault holds application and monitoring credentials outside Git. Its chart remains pinned at 0.34.0 in `gitops/infrastructure/vault/helm-release.yaml`, with values in the same directory. The secrets Flux group installs it alongside ESO after core infrastructure is available.

The existing single-replica Raft configuration and server resource envelope are retained. The unused Vault Agent injector is disabled; workloads receive secrets through ESO, and no workload requests injection. A 10 GiB claim uses `local-path-retain`; the claim and namespace are protected from Flux pruning. The ingress is `vault.homelab.internal`. This is a one-node deployment, not a highly available storage system.

Applying manifests does not initialize Vault, unseal it, configure auth, or create credential values. The [bootstrap runbook](../runbooks/vault-bootstrap.md) covers those operator steps, and `iac/vault` manages Kubernetes auth, the KV mount, policies, and role. No auto-unseal provider is configured, so a restart requires manual unseal.

Monitoring and secret-store readiness wait on successful bootstrap. Homepage and Linkding remain independent. Credential material, recovery keys, Raft snapshots, and Terraform state stay outside Git. A Kubernetes reinstall requires refreshing cluster CA and reviewer-token inputs even when the address is unchanged.
