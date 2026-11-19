---
icon: lucide/shield-check
---

# Recover Vault

Use this runbook when Terraform state is lost or when the Vault installation must be rebuilt. Determine which failure occurred before running commands.

## Refresh authentication after a cluster reinstall

A Kubernetes reinstall changes the cluster CA and service-account tokens even when the API remains at the same Kubernetes API address. Vault Kubernetes auth must be updated with values from the new cluster.

Regenerate `kubernetes_ca_cert` and `token_reviewer_jwt` in the ignored `iac/vault/terraform.tfvars` file using the commands documented in `terraform.tfvars.example`, then apply the workspace:

```shell
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

Do not accept a clean plan as proof that the credentials belong to the current cluster. Terraform can correctly report no changes when both Vault and `terraform.tfvars` contain the same stale values.

Verify the complete authentication and synchronization path:

```shell
kubectl get clustersecretstore vault
kubectl -n monitoring annotate externalsecret grafana-admin \
  force-sync="$(date +%s)" --overwrite
kubectl -n monitoring get externalsecret,secret,pod
```

The store should report `Valid`, the ExternalSecret should report `SecretSynced`, and the monitoring credential gate should become ready. A Vault secret existing at the correct path does not bypass this authentication requirement.

## Recover lost Terraform state

Use this path when Vault still contains the managed resources but `iac/vault/terraform.tfstate` is missing.

```shell
terraform -chdir=iac/vault init
terraform -chdir=iac/vault import vault_auth_backend.kubernetes kubernetes
terraform -chdir=iac/vault import vault_kubernetes_auth_backend_config.this kubernetes
terraform -chdir=iac/vault import vault_mount.external_secrets external-secrets
terraform -chdir=iac/vault import module.eso.vault_policy.this eso
terraform -chdir=iac/vault import module.eso.vault_kubernetes_auth_backend_role.this auth/kubernetes/role/eso
# Import each credential record only if it exists:
terraform -chdir=iac/vault import vault_kv_secret_v2.postiz external-secrets/data/postiz
terraform -chdir=iac/vault import vault_kv_secret_v2.grafana external-secrets/data/monitoring/grafana
terraform -chdir=iac/vault import vault_kv_secret_v2.prometheus external-secrets/data/monitoring/prometheus
terraform -chdir=iac/vault plan
```

Import only objects that already exist. The final plan should be reviewed for unexpected changes before applying it.

## Back up Vault data

Terraform can recreate configuration, but it cannot recreate stored secret values. Create an encrypted, access-controlled Raft snapshot and keep it outside the repository:

```shell
vault operator raft snapshot save vault-raft.snap
```

Treat the snapshot like a collection of production secrets. Never commit snapshots, recovery keys, tokens, `.env`, `terraform.tfvars`, plans, or state.

## Rebuild a lost installation

For a completely empty Vault:

1. Reconcile the Vault and External Secrets manifests with Flux.
2. Follow [Bootstrap Vault](vault-bootstrap.md) without running imports.
3. Restore the original private credential inputs from secure backup before applying Terraform, preserving database passwords and the Postiz JWT secret. Restore other application secrets from their secure backup or source system.
4. Verify the Terraform-managed Postiz and monitoring records. Cloudflared credentials are separate and optional while its bundle is inactive.
5. Verify the `ClusterSecretStore`, `ExternalSecret`, and generated Secret.

Do not run `vault operator init` against an existing initialized Vault.
