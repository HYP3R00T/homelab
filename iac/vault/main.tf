locals {
  workspace_name = "vault"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.kubernetes_backend_path
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.kubernetes_host
  kubernetes_ca_cert     = var.kubernetes_ca_cert
  token_reviewer_jwt     = var.token_reviewer_jwt
  disable_iss_validation = true
}

resource "vault_mount" "external_secrets" {
  path        = var.external_secrets_mount_path
  type        = "kv-v2"
  description = "KV v2 used by External Secrets Operator"
}

module "eso" {
  source = "./eso"

  kubernetes_backend_path          = vault_auth_backend.kubernetes.path
  role_name                        = var.eso_role_name
  bound_service_account_names      = var.eso_bound_service_account_names
  bound_service_account_namespaces = var.eso_bound_service_account_namespaces

  depends_on = [
    vault_kubernetes_auth_backend_config.this,
    vault_mount.external_secrets,
  ]
}
