output "workspace_name" {
  description = "IaC workspace identifier."
  value       = local.workspace_name
}

output "kubernetes_auth_backend_path" {
  description = "Vault auth backend path used for Kubernetes authentication."
  value       = vault_auth_backend.kubernetes.path
}

output "external_secrets_mount_path" {
  description = "Vault KV v2 mount path used by External Secrets."
  value       = vault_mount.external_secrets.path
}
