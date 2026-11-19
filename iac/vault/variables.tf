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
  description = "Stable Shoutrrr encryption key and optional LinkedIn and Meta developer credentials."
  type = object({
    app_key                = string
    linkedin_client_id     = optional(string, "")
    linkedin_client_secret = optional(string, "")
    facebook_client_id     = optional(string, "")
    facebook_client_secret = optional(string, "")
  })
  sensitive = true
  validation {
    condition     = can(regex("^base64:[A-Za-z0-9+/]{43}=$", var.shoutrrr_credentials.app_key))
    error_message = "Supply base64: followed by a base64-encoded 32-byte encryption key."
  }
}

variable "cloudflared_credentials" {
  description = "Optional locally managed tunnel credentials, kept in private tfvars; null omits the tunnel Vault record."
  type = object({
    account_tag   = string
    tunnel_id     = string
    tunnel_secret = string
  })
  sensitive = true
  default   = null
  validation {
    condition = var.cloudflared_credentials == null ? true : alltrue([
      length(trimspace(var.cloudflared_credentials.account_tag)) > 0,
      can(regex("^[0-9a-fA-F-]{36}$", var.cloudflared_credentials.tunnel_id)),
      length(trimspace(var.cloudflared_credentials.tunnel_secret)) > 0,
    ])
    error_message = "Provide the AccountTag, TunnelID, and TunnelSecret from cloudflared's credential JSON, or null."
  }
}
