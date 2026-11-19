# Vault IaC

This directory is the infrastructure-as-code workspace for Vault configuration in the homelab.

It manages the shared Vault bootstrap needed by External Secrets and the credential records consumed by Shoutrrr, Homepage, monitoring, and Cloudflared.

Managed resources:

- the `external-secrets` KV v2 mount
- Kubernetes authentication at `kubernetes`
- Kubernetes auth configuration
- the `eso` policy and Kubernetes auth role with audience `vault`
- Shoutrrr, Grafana, and Prometheus KV v2 records from sensitive tfvars inputs
- the tunnel credential record when `cloudflared_credentials` is supplied
- the Homepage Proxmox record when `homepage_proxmox` is supplied
- the Homepage Tailscale and Cloudflare Tunnel API records when their optional inputs are supplied

Not managed by this workspace:

- Vault installation (managed by Flux and Helm)
- Vault initialization and unsealing (operator steps before Terraform can connect)
- application-generated data such as social access and refresh tokens
- unrelated cloud/provider infrastructure

Follow [Vault bootstrap](../../docs/runbooks/vault-bootstrap.md) before the Terraform commands below. It covers hostname resolution, `VAULT_ADDR`, initialization, unsealing, authentication, and private Terraform inputs in order. Populate all private credential inputs before planning, then verify the External Secrets store and Flux readiness after applying. Having these Terraform files in Git does not mean they have been applied to a Vault installation.

## Usage

Typical workflow from the repository root:

```shell
umask 077
terraform -chdir=iac/vault init
terraform -chdir=iac/vault fmt -check
terraform -chdir=iac/vault validate
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

Prepare the ignored `terraform.tfvars` using the bootstrap runbook first, and review the plan before applying it. The example uses a heredoc for the multiline cluster CA certificate. Keep populated inputs, saved plans, and local state private; `sensitive` hides terminal values but does not encrypt these files.

For local CLI usage, point Terraform at the same ingress URL you use in the browser:

- `vault_addr = "http://vault.homelab.internal"`

Do not use the pod listener port in this workspace unless your workstation can
actually route to it directly.

Keep credential inputs stable between applies. LinkedIn setup changes only its two fields in `shoutrrr_credentials`. Terraform owns the complete KV records; manual edits can be reverted by the next apply. No credential values are exported as Terraform outputs.

Shoutrrr has a separate persistent APP_KEY and optional LinkedIn and Meta credentials in `shoutrrr_credentials`. See [Shoutrrr setup](../../docs/apps/shoutrrr.md).

The optional `cloudflared_credentials` object maps the connector JSON into `cloudflared/tunnel`. Its TunnelID must match the tracked tunnel configuration. See [tunnel credential management](../../docs/runbooks/cloudflared-vault-credentials.md). Cloudflare DNS and tunnel creation remain CLI/provider operations outside this workspace.

The optional `homepage_proxmox` object stores the Proxmox API origin, full token ID, and read-only token secret at `homepage/proxmox`. ESO supplies it to Homepage, and the local Docker helper reads the same record from Vault. See [Homepage Proxmox setup](../../docs/apps/homepage.md#proxmox-widget-and-private-credentials). No Proxmox permissions are changed by this workspace.

The optional `homepage_tailscale` and `homepage_cloudflared` objects manage the provider API credentials for Homepage status widgets at `homepage/tailscale` and `homepage/cloudflared`. The Cloudflare widget token is separate from the tunnel connector credential. See [network widget setup](../../docs/apps/homepage.md#tailscale-and-cloudflare-tunnel-widgets). No tailnet or Cloudflare configuration is changed by these credential records.

## State Recovery

If the local state file goes missing while the managed Vault resources still
exist, import them before planning. A new, empty Vault installation has no
resources to import and uses the normal plan-and-apply workflow instead.

Recovery workflow for an existing Vault installation:

```shell
terraform -chdir=iac/vault init
terraform -chdir=iac/vault import vault_auth_backend.kubernetes kubernetes
terraform -chdir=iac/vault import vault_kubernetes_auth_backend_config.this kubernetes
terraform -chdir=iac/vault import vault_mount.external_secrets external-secrets
terraform -chdir=iac/vault import module.eso.vault_policy.this eso
terraform -chdir=iac/vault import module.eso.vault_kubernetes_auth_backend_role.this auth/kubernetes/role/eso
# Import these only if the credential records already exist:
terraform -chdir=iac/vault import vault_kv_secret_v2.grafana external-secrets/data/monitoring/grafana
terraform -chdir=iac/vault import vault_kv_secret_v2.prometheus external-secrets/data/monitoring/prometheus
terraform -chdir=iac/vault import vault_kv_secret_v2.shoutrrr external-secrets/data/shoutrrr
# Only when cloudflared_credentials is populated and this record already exists:
terraform -chdir=iac/vault import 'vault_kv_secret_v2.cloudflared[0]' external-secrets/data/cloudflared/tunnel
# Only when homepage_proxmox is populated and this record already exists:
terraform -chdir=iac/vault import 'vault_kv_secret_v2.homepage_proxmox[0]' external-secrets/data/homepage/proxmox
# Only when the corresponding input is populated and the record already exists:
terraform -chdir=iac/vault import 'vault_kv_secret_v2.homepage_tailscale[0]' external-secrets/data/homepage/tailscale
terraform -chdir=iac/vault import 'vault_kv_secret_v2.homepage_cloudflared[0]' external-secrets/data/homepage/cloudflared
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
- import IDs must match the configured auth path, mount path, and role name

For safety, keep a backup of:

- this `iac/vault` directory
- your `terraform.tfvars`
- the local Terraform state file until you move to a remote backend

For initialization and configuration, see [Vault bootstrap](../../docs/runbooks/vault-bootstrap.md). For state and data recovery, see [Vault recovery](../../docs/runbooks/vault-recovery.md).

## Managed scope

The configuration aligns Vault with the current GitOps resources by:

- enabling the Kubernetes auth backend at `kubernetes`
- configuring Kubernetes auth for this cluster
- creating the `external-secrets` KV v2 mount
- creating the `eso` policy and Kubernetes auth role

These settings match the current ClusterSecretStore definition under:

- `gitops/infrastructure/secret-store/cluster-secret-store.yaml`
