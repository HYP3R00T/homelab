---
icon: lucide/key-round
---

# Bootstrap Vault

This runbook initializes Vault, configures its Kubernetes integration for External Secrets, and supplies the credentials needed to unblock monitoring. Run commands from the workstation at the repository root.

## What this setup creates

Flux deploys Vault, its persistent volume, the External Secrets Operator, and the Kubernetes resources they need. Terraform then configures these objects inside Vault:

- Kubernetes authentication at `kubernetes`
- Kubernetes API authentication using the `vault-token-reviewer` service account
- a KV v2 secrets engine mounted at `external-secrets`
- an `eso` policy with read access to that mount
- an `eso` role for the `external-secrets` service account with audience `vault`, matching the store TokenRequest

The `ClusterSecretStore` in `gitops/infrastructure/secret-store/cluster-secret-store.yaml` uses those names exactly.

## 1. Check the deployed components

Run these commands on the workstation from the repository root, with the lab Kubernetes context selected and the tools in `mise.toml` installed:

```shell
kubectl config current-context
flux get kustomizations infrastructure secrets
kubectl -n vault get pods
kubectl -n external-secrets get pods
```

Flux must have reconciled `infrastructure` and `secrets`. The secret store and monitoring can remain unready until this bootstrap finishes. A running Vault pod does not mean Vault has been initialized or unsealed.

## 2. Resolve the hostname from the workstation

The shared [local-access guide](../setup/local-access.md) explains all service hostnames and troubleshooting. For Vault, the workstation uses an `/etc/hosts` entry to resolve the internal Vault hostname to the K3s node. Open the file:

```shell
sudoedit /etc/hosts
```

Add `vault.homelab.internal` to the existing entry for the node, or add an entry using this format. Replace `<K3S_NODE_IP>` with the node's current LAN IP address:

```text
<K3S_NODE_IP> vault.homelab.internal

# Example
192.168.0.61 vault.homelab.internal
```

Preserve existing aliases such as `homepage.homelab.internal` and `linkding.homelab.internal`. If the node IP changes, update this entry. Verify resolution:

```shell
getent hosts vault.homelab.internal
kubectl -n vault get ingress vault
```

The hosts entry provides name resolution only on this workstation. The request goes to the node's Traefik ingress, which routes the `vault.homelab.internal` hostname to Vault. Other devices need their own name resolution. External Secrets uses the in-cluster address `http://vault.vault.svc.cluster.local:8200` and does not use the workstation's hosts file.

## 3. Set the Vault address before checking its status

Set the address in the current shell first:

```shell
export VAULT_ADDR=http://vault.homelab.internal
vault status
```

Without `VAULT_ADDR`, the CLI defaults to `https://127.0.0.1:8200`, which targets the workstation instead of the Kubernetes service and can report connection refused.

For subsequent sessions, add this setting to the repository's ignored `.env` file, preserving any existing entries:

```dotenv
VAULT_ADDR=http://vault.homelab.internal
```

`mise.toml` loads this file when the mise environment is active. The explicit `export` above handles the current shell without depending on an environment refresh. Keep `.env` and `iac/vault/terraform.tfvars` outside Git.

## 4. Initialize only a new Vault

Use the `vault status` output to choose the next step:

| Status | Action |
|---|---|
| `Initialized: false` | Initialize, then unseal |
| `Initialized: true`, `Sealed: true` | Skip initialization and use the existing unseal keys |
| `Initialized: true`, `Sealed: false` | Continue to authentication and Terraform configuration |

A sealed Vault makes `vault status` exit with code 2; inspect the displayed fields rather than treating that alone as a connection failure.

Only when `Initialized` is `false`, run:

```shell
vault operator init -key-shares=5 -key-threshold=3
```

This creates five Shamir unseal shares and an initial root token; three distinct shares are required to unseal. Store all shares and the root token securely outside this repository before continuing. These are unseal keys, not recovery keys for auto-unseal. Do not paste them into chat or commit them. Never initialize an already initialized Vault again.

## 5. Unseal and authenticate

For the five-share, three-share-threshold initialization above, run this command three times, entering a different unseal share at each hidden prompt:

```shell
vault operator unseal
```

For an existing Vault, use its original threshold and keys. Check that the result is `Initialized: true` and `Sealed: false`, then log in using the initial root token at the hidden prompt:

```shell
vault status
vault login
```

The CLI normally caches this token through its local token helper. Terraform below uses its separately configured `vault_token` input. A root token is appropriate for initial bootstrap and recovery; use a narrower administrative token for routine work when possible.

Vault seals again after its pod restarts because this installation has no auto-unseal configuration. After a restart, repeat the address setup, unseal, and verification steps; initialization and Terraform bootstrap do not need to be repeated solely because of a restart.

## 6. Prepare Terraform inputs

For a first setup, create the ignored input file from the tracked example. If it already exists, edit it instead of overwriting it:

```shell
cp iac/vault/terraform.tfvars.example iac/vault/terraform.tfvars
```

Populate it with:

- `vault_addr`: `http://vault.homelab.internal` (Terraform does not take this input from the CLI export)
- `vault_token`: the initial root token for bootstrap, or an administrative token with the required permissions
- `kubernetes_host`: the Kubernetes API URL reachable from the Vault pod
- `kubernetes_ca_cert`: the cluster CA certificate
- `token_reviewer_jwt`: the token for `vault-token-reviewer`

The example file contains commands for retrieving the Kubernetes values. The `kubernetes_host` address must be reachable from the Vault pod; do not use a workstation-only localhost proxy address. Do not commit the populated file. Regenerate the CA and reviewer JWT after every Kubernetes reinstall; reusing the old file can cause `403 permission denied` errors from `auth/kubernetes/login`.

## 7. Configure Vault

Initialize providers, review a saved plan, and apply it:

```shell
terraform -chdir=iac/vault init
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

The expected first apply creates five resources. A clean follow-up plan should report no changes:

```shell
terraform -chdir=iac/vault plan
```

The saved plan, variable file, provider directory, and state are ignored by Git. Preserve `iac/vault/terraform.tfstate` securely because it is the active Terraform state for this workspace.

## 8. Verify the secret store

Check the Terraform state and the Vault-backed store:

```shell
terraform -chdir=iac/vault plan
kubectl get clustersecretstore vault
```

A healthy result has no Terraform changes and reports the store as ready. If the store is not ready, inspect its status and the External Secrets logs:

```shell
kubectl describe clustersecretstore vault
kubectl -n external-secrets logs deployment/external-secrets --tail=100
```

## 9. Add monitoring credentials and verify the rollout

Terraform configures Vault authentication, policy, and the KV mount; it does not populate application credentials. Before monitoring can install, create these entries in the `external-secrets` KV v2 mount, using the Vault UI at `http://vault.homelab.internal` or the CLI:

| Entry path within the mount | Required properties |
|---|---|
| `monitoring/grafana` | `username`, `password` |
| `monitoring/prometheus` | `users`: an htpasswd-formatted username and password hash |

See [Monitoring credentials](../infrastructure/kube-prometheus-stack.md#credentials) for the credential commands. The `users` value is not a plaintext password. Keep the resulting credentials outside Git.

Flux waits in order for the secret store, monitoring secrets, the monitoring Helm release, and finally the additional monitors. Once the dependencies become ready, reconciliation proceeds automatically; do not manually install the chart.

```shell
kubectl get clustersecretstore vault
kubectl -n monitoring get externalsecrets
kubectl -n flux-system get kustomizations
kubectl -n monitoring get helmrelease,pods,pvc
```

Expect the store and both ExternalSecrets to report ready, followed by the `monitoring` and `monitoring-monitors` Kustomizations. If a secret reports an error, inspect its events with `kubectl -n monitoring describe externalsecret grafana-admin` or `kubectl -n monitoring describe externalsecret prometheus-basic-auth`.

Add `grafana.homelab.internal` and `prometheus.homelab.internal` to the workstation's hosts entry for the node's current LAN IP address to open their interfaces. Completing this bootstrap does not enable the inactive Postiz, CNPG, or Cloudflared bundles.

## Next steps

- Use [Recover Vault](vault-recovery.md) if state or Vault data is lost.
- If deliberately enabling the inactive tunnel later, use [Store Cloudflared credentials in Vault](cloudflared-vault-credentials.md).
