resource "vault_kv_secret_v2" "homepage_cloudflared" {
  count = nonsensitive(var.homepage_cloudflared == null) ? 0 : 1
  mount = vault_mount.external_secrets.path
  name  = "homepage/cloudflared"
  data_json = jsonencode({
    account-id = var.homepage_cloudflared.account_id
    tunnel-id  = var.homepage_cloudflared.tunnel_id
    api-token  = var.homepage_cloudflared.api_token
  })
}
