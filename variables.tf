variable "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider (TFC, GitHub, etc.)"
  type        = string
}

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "oidc_conditions" {
  description = "Trust policy conditions for the OIDC provider"
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
}

variable "policy_json" {
  description = "IAM policy document JSON to attach to the role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the role"
  type        = map(string)
  default     = {}
}
