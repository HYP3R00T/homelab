resource "vault_kv_secret_v2" "prometheus" {
  mount     = vault_mount.external_secrets.path
  name      = "monitoring/prometheus"
  data_json = jsonencode({ users = var.prometheus_users })
}
