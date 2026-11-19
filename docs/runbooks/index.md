---
icon: lucide/book-open-check
---

# Runbooks

Runbooks own longer bootstrap, rollout, and recovery procedures. For the first-install sequence, start with [Setup](../setup/index.md); component explanations live under [Applications](../apps/index.md) and [Infrastructure](../infrastructure/index.md).

## GitOps and storage

- [Roll out GitOps](gitops-rollout.md): activation order, verification, and rollback
- [Recover retained storage](storage-recovery.md): volume mappings, backup, and rebuild boundaries

## Vault

- [Bootstrap Vault](vault-bootstrap.md): initialize, unseal, configure, and
  validate the External Secrets integration
- [Recover Vault](vault-recovery.md): restore Terraform tracking or rebuild a
  lost Vault installation

## Shoutrrr public tunnel

Cloudflared publishes Shoutrrr only. These procedures are not prerequisites for the other private LAN interfaces.

- [Create a Cloudflared tunnel](cloudflared-tunnel.md): authenticate the CLI,
  create a locally managed tunnel, and record its ID
- [Store Cloudflared credentials in Vault](cloudflared-vault-credentials.md):
  securely copy the generated tunnel credential into Vault

Read the matching component page before changing its architecture.

## Automation boundary

The repository keeps repeatable Kubernetes state in Git, while these steps remain operator-driven:

- create the Linkding owner account on a new installation
- initialize and unseal Vault
- apply the Vault Terraform workspace
- choose and preserve application credentials in private Terraform inputs

Shoutrrr's public tunnel requires Cloudflared authorization, a tunnel credential in private Terraform inputs, and a Cloudflare DNS route. The remaining services use the private LAN setup.

After bootstrap, persistent Kubernetes configuration changes are committed and reconciled by Flux. Do not rely on manual cluster edits for persistent configuration.
