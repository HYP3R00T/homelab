---
icon: lucide/book-key
---

# Bootstrap Vault

This runbook initializes Vault and configures its Kubernetes integration for
External Secrets. Run commands from the repository root.

## What this setup creates

Flux deploys Vault, its persistent volume, the External Secrets Operator, and
the Kubernetes resources they need. Terraform then configures these objects
inside Vault:

- Kubernetes authentication at `kubernetes`
- Kubernetes API authentication using the `vault-token-reviewer` service account
- a KV v2 secrets engine mounted at `external-secrets`
- an `eso` policy with read access to that mount
- an `eso` role for the `external-secrets` service account

The `ClusterSecretStore` in
`gitops/infrastructure/configs/lab/external-secrets/clusterSecretStore.yaml`
uses those names exactly.

## Prerequisites

- the lab Kubernetes context is selected
- Flux has reconciled `infrastructure-controllers` and `infrastructure-configs`
- `vault.homelab.internal` resolves from the workstation
- mise has installed the tools declared in `mise.toml`
- `.env` and `iac/vault/terraform.tfvars` remain outside Git

Check the deployed components:

```shell
kubectl config current-context
flux get kustomizations infrastructure-controllers infrastructure-configs
kubectl -n vault get pods
kubectl -n external-secrets get pods
```

## Initialize a new Vault

Check Vault before initializing it:

```shell
vault status
```

Run initialization only when `Initialized` is `false`:

```shell
vault operator init
```

Store every recovery key and the initial root token in a secure system outside
this repository. Losing both the Vault data and these values makes recovery
impossible. Never initialize an existing Vault again.

For local commands, keep the address, root token, and one unseal key in the
ignored `.env` file as appropriate for this homelab:

```dotenv
VAULT_ADDR=http://vault.homelab.internal
VAULT_TOKEN=<initial-root-token>
VAULT_UNSEAL_KEY=<unseal-key>
```

The root token is suitable for initial bootstrap and recovery. Replace it with
a narrower administrative token for routine Terraform use when possible.

## Unseal Vault

Mise loads `.env`, so the repository task can unseal Vault without placing the
key directly in shell history:

```shell
mise run unseal
vault status
```

If initialization uses an unseal threshold greater than one, submit a distinct
key for each required share with `vault operator unseal`.

Vault seals again after its pod restarts. Repeat this step after restarts unless
an auto-unseal mechanism is configured.

## Prepare Terraform inputs

Create the ignored input file from the tracked example:

```shell
cp iac/vault/terraform.tfvars.example iac/vault/terraform.tfvars
```

Populate it with:

- `vault_addr`: the workstation-reachable Vault URL
- `vault_token`: an administrative Vault token
- `kubernetes_host`: the Kubernetes API URL reachable from the Vault pod
- `kubernetes_ca_cert`: the cluster CA certificate
- `token_reviewer_jwt`: the token for `vault-token-reviewer`

The example file contains commands for retrieving the Kubernetes values. Do
not commit the populated file.

## Configure Vault

Initialize providers, review a saved plan, and apply it:

```shell
tf -chdir=iac/vault init
tf -chdir=iac/vault plan -out=tfplan
tf -chdir=iac/vault apply tfplan
```

The expected first apply creates five resources. A clean follow-up plan should
report no changes:

```shell
tf -chdir=iac/vault plan
```

The saved plan, variable file, provider directory, and state are ignored by
Git. Preserve `iac/vault/terraform.tfstate` securely because it is the active
Terraform state for this workspace.

## Verify the bootstrap

Check the Terraform state and the Vault-backed store:

```shell
tf -chdir=iac/vault plan
kubectl get clustersecretstore vault
```

A healthy result has no Terraform changes and reports the store as ready. If
the store is not ready, inspect its status and the External Secrets logs:

```shell
kubectl describe clustersecretstore vault
kubectl -n external-secrets logs deployment/external-secrets --tail=100
```

## Next steps

- Use [Store Cloudflared credentials in Vault](cloudflared-vault-credentials.md)
  to add the locally managed tunnel credential.
- Use [Recover Vault](vault-recovery.md) if state or Vault data is lost.
