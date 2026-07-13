---
icon: lucide/key-square
---

# Store Cloudflared Credentials in Vault

This runbook copies the locally generated tunnel credential JSON into Vault
without exposing its contents in Git or command output.

## Prerequisites

- [Bootstrap Vault](vault-bootstrap.md) is complete
- [Create a Cloudflared tunnel](cloudflared-tunnel.md) is complete
- `.env` contains `VAULT_ADDR`, `VAULT_TOKEN`, `VAULT_UNSEAL_KEY`, and
  `CLOUDFLARE_TUNNEL_ID`

## Authenticate to Vault

Unseal Vault when necessary:

```shell
vault operator unseal "$VAULT_UNSEAL_KEY"
```

Authenticate with the administrative token loaded from `.env`:

```shell
vault login -no-print "$VAULT_TOKEN"
vault token lookup
```

When `VAULT_TOKEN` is set, Vault may warn that the environment value takes
precedence over the token saved by `vault login`. This is expected.

## Store the credential

```shell
vault kv put -mount=external-secrets cloudflared/tunnel "credentials=@${HOME}/.cloudflared/${CLOUDFLARE_TUNNEL_ID}.json"
```

The command should report versioned metadata for
`external-secrets/data/cloudflared/tunnel`.

Verify metadata without printing the credential:

```shell
vault kv metadata get -mount=external-secrets cloudflared/tunnel
```

## Reconcile the GitOps configuration

After the Cloudflared manifest changes are committed and pushed, reconcile the
Git source and infrastructure configuration:

```shell
flux reconcile kustomization infrastructure-configs --with-source
kubectl -n cloudflared annotate externalsecret cloudflared-external-secret \
  force-sync="$(date +%s)" --overwrite
kubectl -n cloudflared rollout status deployment/cloudflared --timeout=180s
```

## Troubleshoot a 403 response

A `403 permission denied` response means the active Vault token cannot write to
the KV path.

```shell
vault token lookup
vault token capabilities external-secrets/data/cloudflared/tunnel
```

The token needs `create` and `update`. The `eso` policy is intentionally
read-only, so use the initial root token or another administrative token for
this write operation.

## Verify the connector

After Flux applies the Cloudflared manifests, verify the secret, pod, tunnel,
and public endpoint:

```shell
kubectl -n cloudflared get externalsecret,secret,pod
cloudflared tunnel info "$CLOUDFLARE_TUNNEL_ID"
curl --fail --head https://linkding.hyperoot.dev
```
