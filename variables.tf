variable "provider_url" {
  description = "OIDC provider URL (e.g. https://app.terraform.io)"
  type        = string
}

variable "client_id_list" {
  description = "List of client IDs (audiences) for the OIDC provider"
  type        = list(string)
}

variable "thumbprint_list" {
  description = "List of server certificate thumbprints for the OIDC provider"
  type        = list(string)
}

variable "roles" {
  description = "Map of IAM roles to create with OIDC trust policies"
  type = map(object({
    role_name = string
    oidc_conditions = list(object({
      test     = string
      variable = string
      values   = list(string)
    }))
    policy_json = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
