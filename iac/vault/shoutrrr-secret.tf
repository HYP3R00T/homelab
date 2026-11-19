resource "vault_kv_secret_v2" "shoutrrr" {
  mount = vault_mount.external_secrets.path
  name  = "shoutrrr"
  data_json = jsonencode({
    app-key                = var.shoutrrr_credentials.app_key
    linkedin-client-id     = var.shoutrrr_credentials.linkedin_client_id
    linkedin-client-secret = var.shoutrrr_credentials.linkedin_client_secret
    facebook-client-id     = var.shoutrrr_credentials.facebook_client_id
    facebook-client-secret = var.shoutrrr_credentials.facebook_client_secret
  })
}
