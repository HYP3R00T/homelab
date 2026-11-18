# Cloudflared

Cloudflared is retained as an optional public tunnel client in `gitops/infrastructure/cloudflared`. It is not reachable from the active Flux entrypoint, so this cleanup does not expose applications publicly.

The retained bundle contains its Deployment, namespace, ExternalSecret, and a ConfigMap input describing the old Linkding/Postiz routes. The tunnel ID and public hostnames are inactive configuration, not proof that the tunnel or provider DNS is live. Review them before any future activation.

A future activation needs Vault/ESO, approved tunnel credentials, and a separately reviewed public-access decision. Keeping Vault and ESO does not require running the tunnel. See [the optional tunnel runbook](../runbooks/cloudflared-tunnel.md) only when public access is intended.
