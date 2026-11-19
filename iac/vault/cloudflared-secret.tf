resource "vault_kv_secret_v2" "cloudflared" {
  count = var.cloudflared_credentials == null ? 0 : 1
  mount = vault_mount.external_secrets.path
  name  = "cloudflared/tunnel"
  data_json = jsonencode({
    credentials = jsonencode({
      AccountTag   = var.cloudflared_credentials.account_tag
      TunnelID     = var.cloudflared_credentials.tunnel_id
      TunnelSecret = var.cloudflared_credentials.tunnel_secret
    })
  })
}
