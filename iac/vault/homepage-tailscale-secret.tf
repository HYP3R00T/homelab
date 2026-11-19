resource "vault_kv_secret_v2" "homepage_tailscale" {
  count = nonsensitive(var.homepage_tailscale == null) ? 0 : 1
  mount = vault_mount.external_secrets.path
  name  = "homepage/tailscale"
  data_json = jsonencode({
    device-id = var.homepage_tailscale.device_id
    api-token = var.homepage_tailscale.api_token
  })
}
