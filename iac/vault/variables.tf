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

variable "postiz_credentials" {
  description = "Postiz credentials persisted in the private tfvars file. Keep existing values when adding provider credentials."
  type = object({
    jwt_secret                 = string
    database_password          = string
    temporal_database_password = string
    redis_password             = string
    linkedin_client_id         = optional(string, "")
    linkedin_client_secret     = optional(string, "")
  })
  sensitive = true

  validation {
    condition = alltrue([
      length(trimspace(var.postiz_credentials.jwt_secret)) > 0,
      can(regex("^[A-Za-z0-9._~-]+$", var.postiz_credentials.database_password)),
      can(regex("^[A-Za-z0-9._~-]+$", var.postiz_credentials.temporal_database_password)),
      can(regex("^[A-Za-z0-9._~-]+$", var.postiz_credentials.redis_password)),
    ])
    error_message = "Supply a nonempty JWT secret and URL-safe database/Redis passwords; openssl rand -hex 32 generates suitable values."
  }
}

variable "grafana_credentials" {
  description = "Grafana administrator username and password, supplied through private tfvars."
  type = object({
    username = string
    password = string
  })
  sensitive = true

  validation {
    condition     = length(trimspace(var.grafana_credentials.username)) > 0 && length(trimspace(var.grafana_credentials.password)) > 0
    error_message = "Supply a nonempty Grafana username and password."
  }
}

variable "prometheus_users" {
  description = "One htpasswd bcrypt entry for Prometheus Basic Auth, including username and hash."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^:\\r\\n]+:\\$2[aby]\\$[0-9]{2}\\$[./A-Za-z0-9]{53}$", var.prometheus_users))
    error_message = "Supply the complete username:bcrypt-hash line produced by htpasswd -nB prometheus."
  }
}

variable "shoutrrr_credentials" {
  description = "Stable Shoutrrr encryption key and optional LinkedIn developer credentials."
  type = object({
    app_key                = string
    linkedin_client_id     = optional(string, "")
    linkedin_client_secret = optional(string, "")
  })
  sensitive = true
  validation {
    condition     = can(regex("^base64:[A-Za-z0-9+/]{43}=$", var.shoutrrr_credentials.app_key))
    error_message = "Supply base64: followed by a base64-encoded 32-byte encryption key."
  }
}
