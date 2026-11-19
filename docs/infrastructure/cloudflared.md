---
icon: lucide/cloud
---

# Cloudflared

Cloudflared connects an origin service to an optional Cloudflare public tunnel. Its retained bundle in `gitops/infrastructure/cloudflared` is **not activated**. The baseline homelab uses private LAN ingress and does not need a tunnel or Cloudflare DNS configuration.

The bundle contains a Deployment, namespace, ExternalSecret, and ConfigMap input with the retained Linkding route. Retained tunnel IDs and public hostnames describe that unused configuration, not a live public endpoint. Keeping Vault and ESO does not require running Cloudflared.

## Before activation

A future public-access decision must review the target application, origin routes, provider DNS, and approved tunnel credential. Only then follow [Create a tunnel](../runbooks/cloudflared-tunnel.md) and [Store its credential in Vault](../runbooks/cloudflared-vault-credentials.md), with a separate Flux readiness boundary for secret delivery.

Do not follow those procedures to complete the private setup. If deliberately enabled later, verify the ExternalSecret, deployment, and intended provider route individually. See [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) for upstream configuration and behavior.
