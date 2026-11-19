---
icon: lucide/cloud-cog
---

# Create a Cloudflared tunnel

This homelab uses the locally managed `homelab` tunnel to publish Shoutrrr only at `https://shoutrrr.hyperoot.dev`. The Cloudflare zone must be under your control. The other homelab interfaces stay private.

## Authorize the workstation

```shell
cloudflared tunnel login
cloudflared tunnel list
```

In the browser, authorize the `hyperoot.dev` zone. Cloudflared writes `~/.cloudflared/cert.pem`; this account-level management credential stays on the workstation. Never commit it or deploy it in Kubernetes.

## Reuse or create the tunnel

Prefer the existing `homelab` tunnel. Create it only if the list confirms it is absent:

```shell
cloudflared tunnel create homelab
```

Use the resulting UUID in `gitops/infrastructure/cloudflared/config.yaml` and the private Terraform input. If its connector JSON is missing, recover it into private storage without printing the token:

```shell
umask 077
mkdir -p .cache/cloudflared
cloudflared tunnel token --cred-file .cache/cloudflared/tunnel.json <TUNNEL_ID>
```

Continue with [Vault credential management](cloudflared-vault-credentials.md) before starting the connector. On a fresh Shoutrrr database, create its initial owner locally before public exposure.

## Route the public hostname

```shell
cloudflared tunnel route dns <TUNNEL_ID> shoutrrr.hyperoot.dev
```

This creates the Cloudflare DNS CNAME to the tunnel. If the hostname already points elsewhere, inspect that record before replacing it. The Kubernetes tunnel configuration forwards only this hostname to the Shoutrrr Service and returns 404 for everything else. Do not add the old Linkding route.

Cloudflare supplies public HTTPS. Shoutrrr's APP_URL, secure cookies, trusted-proxy range, and provider callbacks use the public origin; the origin container remains HTTP inside the cluster. No local CA or router port forwarding is needed.

## Verify

```shell
cloudflared tunnel info homelab
kubectl -n cloudflared get externalsecret,pods
curl --fail https://shoutrrr.hyperoot.dev/up
```

Open the public address and sign in. Register `https://shoutrrr.hyperoot.dev/accounts/callback/meta` in Meta and `https://shoutrrr.hyperoot.dev/accounts/callback/linkedin` in LinkedIn before starting fresh account authorizations. Preserve existing provider credentials and APP_KEY.

See [Cloudflare's tunnel commands](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/tunnel-useful-commands/).
