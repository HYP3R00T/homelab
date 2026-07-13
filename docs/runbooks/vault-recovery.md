---
icon: lucide/shield-check
---

# Recover Vault

Use this runbook when Terraform state is lost or when the Vault installation
must be rebuilt. Determine which failure occurred before running commands.

## Recover lost Terraform state

Use this path when Vault still contains the managed resources but
`iac/vault/terraform.tfstate` is missing.

```shell
tf -chdir=iac/vault init
tf -chdir=iac/vault import vault_auth_backend.kubernetes kubernetes
tf -chdir=iac/vault import vault_kubernetes_auth_backend_config.this kubernetes
tf -chdir=iac/vault import vault_mount.external_secrets external-secrets
tf -chdir=iac/vault import module.eso.vault_policy.this eso
tf -chdir=iac/vault import module.eso.vault_kubernetes_auth_backend_role.this auth/kubernetes/role/eso
tf -chdir=iac/vault plan
```

Import only objects that already exist. The final plan should be reviewed for
unexpected changes before applying it.

## Back up Vault data

Terraform can recreate configuration, but it cannot recreate stored secret
values. Create an encrypted, access-controlled Raft snapshot and keep it
outside the repository:

```shell
vault operator raft snapshot save vault-raft.snap
```

Treat the snapshot like a collection of production secrets. Never commit
snapshots, recovery keys, tokens, `.env`, `terraform.tfvars`, plans, or state.

## Rebuild a lost installation

For a completely empty Vault:

1. Reconcile the Vault and External Secrets manifests with Flux.
2. Follow [Bootstrap Vault](vault-bootstrap.md) without running imports.
3. Restore application secrets from a secure backup or source system.
4. Recreate the Cloudflared tunnel credentials in Vault.
5. Verify the `ClusterSecretStore`, `ExternalSecret`, and generated Secret.

Do not run `vault operator init` against an existing initialized Vault.
