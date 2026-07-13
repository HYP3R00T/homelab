---
icon: lucide/book-open-check
---

# Runbooks

Runbooks contain repeatable operational procedures. Each one states its
prerequisites, commands, verification steps, and recovery considerations.

## Vault

- [Bootstrap Vault](vault-bootstrap.md): initialize, unseal, configure, and
  validate the External Secrets integration
- [Recover Vault](vault-recovery.md): restore Terraform tracking or rebuild a
  lost Vault installation

## Cloudflared

- [Create a Cloudflared tunnel](cloudflared-tunnel.md): authenticate the CLI,
  create a locally managed tunnel, and record its ID
- [Store Cloudflared credentials in Vault](cloudflared-vault-credentials.md):
  securely copy the generated tunnel credential into Vault

Read the matching page under [Services](../services/index.md) before changing a
component's architecture.

## Automation boundary

The repository keeps repeatable Kubernetes state in Git, while a small set of
bootstrap actions remains operator-driven because it creates or handles
external credentials:

- initialize and unseal Vault
- apply the Vault Terraform workspace
- authenticate Cloudflared and create the tunnel
- write tunnel credentials to Vault
- create the Cloudflare DNS route

After bootstrap, Kubernetes changes are committed and reconciled by Flux. Do
not rely on manual cluster edits for persistent configuration.
