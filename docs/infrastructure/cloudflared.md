---
icon: lucide/cloud
---

# Cloudflared

Cloudflared publishes only `https://shoutrrr.hyperoot.dev`. The connector establishes outbound connections to Cloudflare and forwards that hostname directly to `http://shoutrrr.shoutrrr.svc.cluster.local:8080`. All other tunnel hostnames return 404; Homepage, Linkding, Vault, and Flux UI remain LAN-only.

The `cloudflared` Flux group depends on `secret-store` and `shoutrrr`. Terraform writes the connector credential to `external-secrets/cloudflared/tunnel`; ESO creates `cloudflared-secret`. The account-level Cloudflare management certificate stays on the workstation and is never mounted in the pod.

The connector requests 100m CPU and 128 MiB memory, with limits of 500m CPU and 256 MiB memory. Its readiness probe uses `/ready` on port 2000 to check its edge connection. The image is pinned to `cloudflare/cloudflared:2026.11.1`. Public TLS terminates at Cloudflare; the private origin Service uses HTTP.

## Setup and recovery

Follow [Create a tunnel](../runbooks/cloudflared-tunnel.md), then [Manage its credential in Vault](../runbooks/cloudflared-vault-credentials.md). The configured tunnel UUID, Cloudflare DNS record, and credential TunnelID must agree. A healthy pod alone does not verify DNS, the public certificate, OAuth redirects, or media retrieval.

For a fresh installation, create the Shoutrrr owner over a local connection before starting the public connector. `INSTANCE_REGISTRATIONS_ENABLED=false` blocks further public registration after an owner exists; it still permits initial registration. Keep the existing owner database and APP_KEY during upgrades.

Shoutrrr supplies its own account authentication. No Cloudflare Access application or object-storage service is created by this repository. Any future Access or WAF changes must preserve provider access to signed media URLs. See [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) and [Shoutrrr setup](../apps/shoutrrr.md).

## Verify

```shell
kubectl -n cloudflared get externalsecret,pods
kubectl -n cloudflared rollout status deployment/cloudflared
cloudflared tunnel info homelab
curl --fail https://shoutrrr.hyperoot.dev/up
```

No router port forwarding or local certificate installation is required. Public exposure applies to Shoutrrr only; a tunnel is not an authentication boundary for that application.
