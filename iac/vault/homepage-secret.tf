resource "vault_kv_secret_v2" "homepage_proxmox" {
  count = nonsensitive(var.homepage_proxmox == null) ? 0 : 1
  mount = vault_mount.external_secrets.path
  name  = "homepage/proxmox"
  data_json = jsonencode({
    url          = var.homepage_proxmox.url
    token-id     = var.homepage_proxmox.token_id
    token-secret = var.homepage_proxmox.token_secret
  })
}
