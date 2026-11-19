resource "vault_kv_secret_v2" "grafana" {
  mount     = vault_mount.external_secrets.path
  name      = "monitoring/grafana"
  data_json = jsonencode(var.grafana_credentials)
}
