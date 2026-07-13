resource "vault_policy" "this" {
  name   = var.role_name
  policy = file("${path.module}/policy.hcl")
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = var.kubernetes_backend_path
  role_name                        = var.role_name
  bound_service_account_names      = var.bound_service_account_names
  bound_service_account_namespaces = var.bound_service_account_namespaces
  token_policies                   = [vault_policy.this.name]
}
