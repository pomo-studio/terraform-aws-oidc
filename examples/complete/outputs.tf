output "terraform_cloud_role_arns" {
  description = "ARNs of Terraform Cloud IAM roles"
  value = {
    production = module.terraform_cloud_oidc.role_arns["production"]
    staging    = module.terraform_cloud_oidc.role_arns["staging"]
  }
}

output "github_actions_role_arns" {
  description = "ARNs of GitHub Actions IAM roles"
  value = {
    frontend_deploy = module.github_actions_oidc.role_arns["frontend_deploy"]
    backend_deploy  = module.github_actions_oidc.role_arns["backend_deploy"]
  }
}

output "gitlab_ci_role_arn" {
  description = "ARN of GitLab CI IAM role"
  value = module.gitlab_ci_oidc.role_arns["ci_deploy"]
}

output "oidc_provider_arns" {
  description = "ARNs of OIDC providers"
  value = {
    terraform_cloud = module.terraform_cloud_oidc.provider_arn
    github_actions  = module.github_actions_oidc.provider_arn
    gitlab_ci       = module.gitlab_ci_oidc.provider_arn
  }
}