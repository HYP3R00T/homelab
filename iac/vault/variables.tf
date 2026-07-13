variable "vault_addr" {
  description = "Vault server address."
  type        = string
  default     = "http://vault.homelab.internal"
}

variable "vault_token" {
  description = "Vault token used by Terraform."
  type        = string
  sensitive   = true
}

variable "kubernetes_host" {
  description = "Kubernetes API server URL."
  type        = string
}

variable "kubernetes_ca_cert" {
  description = "Kubernetes CA certificate used by Vault Kubernetes auth."
  type        = string
}

variable "token_reviewer_jwt" {
  description = "Token reviewer JWT from the vault-token-reviewer service account."
  type        = string
  sensitive   = true
}

variable "kubernetes_backend_path" {
  description = "Vault auth mount path for Kubernetes auth."
  type        = string
  default     = "kubernetes"
}

variable "external_secrets_mount_path" {
  description = "KV v2 mount path used by External Secrets."
  type        = string
  default     = "external-secrets"
}

variable "eso_role_name" {
  description = "Vault Kubernetes auth role name for External Secrets."
  type        = string
  default     = "eso"
}

variable "eso_bound_service_account_names" {
  description = "Service account names allowed to use the ESO Vault role."
  type        = list(string)
  default     = ["external-secrets"]
}

variable "eso_bound_service_account_namespaces" {
  description = "Namespaces allowed to use the ESO Vault role."
  type        = list(string)
  default     = ["external-secrets"]
}
