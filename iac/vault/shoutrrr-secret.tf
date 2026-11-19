resource "vault_kv_secret_v2" "shoutrrr" {
  mount = vault_mount.external_secrets.path
  name  = "shoutrrr"
  data_json = jsonencode({
    app-key                = var.shoutrrr_credentials.app_key
    linkedin-client-id     = var.shoutrrr_credentials.linkedin_client_id
    linkedin-client-secret = var.shoutrrr_credentials.linkedin_client_secret
  })
}
