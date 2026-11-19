resource "vault_kv_secret_v2" "postiz" {
  mount = vault_mount.external_secrets.path
  name  = "postiz"

  data_json = jsonencode({
    jwt-secret                 = var.postiz_credentials.jwt_secret
    postiz-database-password   = var.postiz_credentials.database_password
    temporal-database-password = var.postiz_credentials.temporal_database_password
    redis-password             = var.postiz_credentials.redis_password
    linkedin-client-id         = var.postiz_credentials.linkedin_client_id
    linkedin-client-secret     = var.postiz_credentials.linkedin_client_secret
  })
}
