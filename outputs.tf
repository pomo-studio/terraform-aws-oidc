output "provider_arn" {
  description = "ARN of the OIDC identity provider"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "role_arns" {
  description = "Map of role keys to IAM role ARNs"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of role keys to IAM role names"
  value       = { for k, v in aws_iam_role.this : k => v.name }
}
