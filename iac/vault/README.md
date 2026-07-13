# Vault IaC

This directory is the infrastructure-as-code workspace for Vault configuration in the homelab.

It manages the shared Vault bootstrap needed by External Secrets.

Managed resources:

- the `external-secrets` KV v2 mount
- Kubernetes authentication at `kubernetes`
- Kubernetes auth configuration
- the `eso` policy and Kubernetes auth role

Out of scope for the first pass:

- bulk secret values
- unrelated cloud/provider infrastructure

## Usage

Typical workflow from the repository root:

```shell
terraform -chdir=iac/vault init
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

For local CLI usage, point Terraform at the same ingress URL you use in the browser:

- `vault_addr = "http://vault.homelab.internal"`

Do not use the pod listener port in this workspace unless your workstation can
actually route to it directly.

## State Recovery

If the local state file goes missing while the managed Vault resources still
exist, import them before planning. Imports are explicit so a new Vault
installation can plan and create resources that do not exist yet.

Recovery workflow:

```shell
terraform -chdir=iac/vault init
terraform -chdir=iac/vault import vault_auth_backend.kubernetes kubernetes
terraform -chdir=iac/vault import vault_kubernetes_auth_backend_config.this kubernetes
terraform -chdir=iac/vault import vault_mount.external_secrets external-secrets
terraform -chdir=iac/vault import module.eso.vault_policy.this eso
terraform -chdir=iac/vault import module.eso.vault_kubernetes_auth_backend_role.this auth/kubernetes/role/eso
terraform -chdir=iac/vault plan
```

These commands re-associate Terraform with:

- re-imports the Vault auth backend at `kubernetes`
- re-imports the Kubernetes auth backend config at `kubernetes`
- re-imports the KV v2 mount at `external-secrets`
- re-imports the `eso` policy
- re-imports the `eso` Kubernetes auth role

Important notes:

- `terraform refresh` only helps when state already exists
- if the state file is gone, import is how Terraform rebuilds resource tracking
- recovery succeeds only if the live Vault objects still match this configuration
- import only resources that already exist in Vault
- if you rename the auth path, mount path, or role name later, update the import IDs too

For safety, keep a backup of:

- this `iac/vault` directory
- your `terraform.tfvars`
- the local Terraform state file until you move to a remote backend

For initialization and configuration, see
`docs/runbooks/vault-bootstrap.md`. For state and data recovery, see
`docs/runbooks/vault-recovery.md`.

## First-pass scope

The first-pass configuration aligns Vault with the current GitOps resources by:

- enabling the Kubernetes auth backend at `kubernetes`
- configuring Kubernetes auth for this cluster
- creating the `external-secrets` KV v2 mount
- creating the `eso` policy and Kubernetes auth role

These settings match the current ClusterSecretStore definition under:

- `gitops/infrastructure/configs/lab/external-secrets/clusterSecretStore.yaml`
