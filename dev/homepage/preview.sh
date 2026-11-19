#!/bin/sh
# Read credentials from Vault into this process environment, never into config files.
set -eu
preview_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
HOMEPAGE_VAR_PROXMOX_URL=$(vault kv get -field=url external-secrets/homepage/proxmox)
HOMEPAGE_VAR_PROXMOX_TOKEN_ID=$(vault kv get -field=token-id external-secrets/homepage/proxmox)
HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET=$(vault kv get -field=token-secret external-secrets/homepage/proxmox)
export HOMEPAGE_VAR_PROXMOX_URL HOMEPAGE_VAR_PROXMOX_TOKEN_ID HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET
if ! HOMEPAGE_VAR_TAILSCALE_DEVICE_ID=$(vault kv get -field=device-id external-secrets/homepage/tailscale 2>/dev/null); then
  HOMEPAGE_VAR_TAILSCALE_DEVICE_ID=''
  printf '%s\n' 'Homepage tailscale device-id unavailable in Vault.' >&2
fi
export HOMEPAGE_VAR_TAILSCALE_DEVICE_ID
if ! HOMEPAGE_VAR_TAILSCALE_API_TOKEN=$(vault kv get -field=api-token external-secrets/homepage/tailscale 2>/dev/null); then
  HOMEPAGE_VAR_TAILSCALE_API_TOKEN=''
  printf '%s\n' 'Homepage tailscale api-token unavailable in Vault.' >&2
fi
export HOMEPAGE_VAR_TAILSCALE_API_TOKEN
if ! HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID=$(vault kv get -field=account-id external-secrets/homepage/cloudflared 2>/dev/null); then
  HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID=''
  printf '%s\n' 'Homepage cloudflared account-id unavailable in Vault.' >&2
fi
export HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID
if ! HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID=$(vault kv get -field=tunnel-id external-secrets/homepage/cloudflared 2>/dev/null); then
  HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID=''
  printf '%s\n' 'Homepage cloudflared tunnel-id unavailable in Vault.' >&2
fi
export HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID
if ! HOMEPAGE_VAR_CLOUDFLARED_API_TOKEN=$(vault kv get -field=api-token external-secrets/homepage/cloudflared 2>/dev/null); then
  HOMEPAGE_VAR_CLOUDFLARED_API_TOKEN=''
  printf '%s\n' 'Homepage cloudflared api-token unavailable in Vault.' >&2
fi
export HOMEPAGE_VAR_CLOUDFLARED_API_TOKEN
exec docker compose -f "$preview_dir/compose.yaml" up -d --force-recreate
