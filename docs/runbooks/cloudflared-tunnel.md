---
icon: lucide/cloud-cog
---

# Create a Cloudflared Tunnel

This runbook creates the locally managed `homelab` tunnel from the Cloudflared
CLI and records its ID for later commands.

## Prerequisites

- a Cloudflare account and a domain managed by Cloudflare
- Cloudflared installed through `mise.toml`
- permission to authorize Cloudflared for the domain
- `.env` ignored by Git

## Authenticate the CLI

```shell
cloudflared tunnel login
```

Open the one-time URL, sign in, and select the domain to authorize. Cloudflared
writes the account-level management certificate to
`~/.cloudflared/cert.pem`. Do not deploy or commit this certificate.

## Create the tunnel

Check for an existing tunnel first:

```shell
cloudflared tunnel list
```

Create it only when it does not already exist:

```shell
cloudflared tunnel create homelab
```

Cloudflared writes `~/.cloudflared/<tunnel-id>.json`. This file contains the
per-tunnel credential and must remain secret.

## Record the ID

```shell
cloudflared tunnel list -n homelab -o json | jq -r '.[0].id'
```

Add the result to `.env`:

```dotenv
CLOUDFLARE_TUNNEL_ID=<tunnel-id>
```

Verify the tunnel:

```shell
cloudflared tunnel info "$CLOUDFLARE_TUNNEL_ID"
```

The message `does not have any active connection` is expected until a local or
Kubernetes Cloudflared process starts using the credential.

Create the Linkding DNS route:

```shell
cloudflared tunnel route dns "$CLOUDFLARE_TUNNEL_ID" linkding.hyperoot.dev
```

Continue with
[Store Cloudflared credentials in Vault](cloudflared-vault-credentials.md).

## Reference

Cloudflare maintains a list of
[useful locally managed tunnel commands](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/tunnel-useful-commands/).
