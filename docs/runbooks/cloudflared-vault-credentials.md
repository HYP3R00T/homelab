---
icon: lucide/key-square
---

# Manage Cloudflared credentials in Vault

Terraform owns the locally managed tunnel credential at `external-secrets/cloudflared/tunnel`. ESO reads its `credentials` property into `cloudflared-secret`, mounted as `credentials.json`. No secret values belong in Git.

## Private inputs

Complete [Vault bootstrap](vault-bootstrap.md) and [tunnel authorization](cloudflared-tunnel.md). Copy the three fields from the connector JSON into the ignored `iac/vault/terraform.tfvars`, using the mapping below. Preserve the existing application and monitoring inputs.

| Connector JSON field | Terraform field |
| --- | --- |
| AccountTag | account_tag |
| TunnelID | tunnel_id |
| TunnelSecret | tunnel_secret |

```hcl
cloudflared_credentials = {
  account_tag   = "your-account-tag"
  tunnel_id     = "your-tunnel-uuid"
  tunnel_secret = "your-tunnel-secret"
}
```

The tracked example includes commands to generate or recover the JSON. These are connector credentials; `cert.pem` grants account-level management access and must stay on the workstation. The tunnel UUID must also match the tracked connector config and DNS route.

## Plan and apply

```shell
umask 077
terraform -chdir=iac/vault validate
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

For an existing baseline workspace, enabling the optional input creates one `vault_kv_secret_v2.cloudflared[0]` record with no application credential changes. `null` omits that resource and would plan its removal if it was previously managed; review before applying. The complete workspace creates nine resources with the tunnel enabled, or eight without it.

If the record already exists outside Terraform, import it after populating the input rather than overwriting it blindly:

```shell
terraform -chdir=iac/vault import 'vault_kv_secret_v2.cloudflared[0]' external-secrets/data/cloudflared/tunnel
```

Terraform state and plans contain secret material and remain local and ignored. Back up them and the matching private inputs securely. Restoring Vault data does not restore a lost Terraform state file.

## Sync and verify

After the GitOps group reaches the cluster:

```shell
kubectl -n cloudflared annotate externalsecret cloudflared-external-secret force-sync="$(date +%s)" --overwrite
kubectl -n cloudflared get externalsecret,pods
kubectl -n cloudflared rollout status deployment/cloudflared --timeout=180s
curl --fail https://shoutrrr.hyperoot.dev/up
```

Wait for a new ExternalSecret refresh and Ready condition before restarting an existing connector after rotation. Do not print the generated Secret or credential JSON. A 403 from Vault means the active Terraform token lacks rights on the path; the ESO read-only policy is deliberately insufficient for writing credentials.
