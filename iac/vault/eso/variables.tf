variable "role_name" {
  description = "Vault Kubernetes auth role name."
  type        = string
  default     = "eso"
}

variable "bound_service_account_names" {
  description = "Service account names allowed to use this Vault role."
  type        = list(string)
  default     = ["external-secrets"]
}

variable "bound_service_account_namespaces" {
  description = "Namespaces allowed to use this Vault role."
  type        = list(string)
  default     = ["external-secrets"]
}

variable "kubernetes_backend_path" {
  description = "Vault auth backend path for Kubernetes auth."
  type        = string
  default     = "kubernetes"
}
