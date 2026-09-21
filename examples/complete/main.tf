terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# =============================================================================
# Terraform Cloud OIDC Configuration
# =============================================================================

module "terraform_cloud_oidc" {
  source  = "../.."
  version = "~> 2.0"

  provider_url    = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  roles = {
    # Production workspace role
    production = {
      role_name = "terraform-cloud-production"
      role_description = "IAM role for Terraform Cloud production workspace"
      max_session_duration = 3600  # 1 hour
      oidc_conditions = [
        {
          test     = "StringEquals"
          variable = "app.terraform.io:aud"
          values   = ["aws.workload.identity"]
        },
        {
          test     = "StringLike"
          variable = "app.terraform.io:sub"
          values   = ["organization:my-org:project:production:workspace:*:run_phase:*"]
        }
      ]
      policy_json = data.aws_iam_policy_document.tfc_production.json
    }

    # Staging workspace role
    staging = {
      role_name = "terraform-cloud-staging"
      role_description = "IAM role for Terraform Cloud staging workspace"
      max_session_duration = 3600
      oidc_conditions = [
        {
          test     = "StringEquals"
          variable = "app.terraform.io:aud"
          values   = ["aws.workload.identity"]
        },
        {
          test     = "StringLike"
          variable = "app.terraform.io:sub"
          values   = ["organization:my-org:project:staging:workspace:*:run_phase:*"]
        }
      ]
      policy_json = data.aws_iam_policy_document.tfc_staging.json
    }
  }
}

# =============================================================================
# GitHub Actions OIDC Configuration
# =============================================================================

module "github_actions_oidc" {
  source  = "../.."
  version = "~> 2.0"

  provider_url    = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  roles = {
    # Frontend deployment role
    frontend_deploy = {
      role_name = "github-actions-frontend-deploy"
      role_description = "IAM role for GitHub Actions frontend deployment"
      max_session_duration = 900  # 15 minutes
      oidc_conditions = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = ["repo:my-org/my-frontend:*"]
        },
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:ref"
          values   = ["refs/heads/main"]
        }
      ]
      policy_json = data.aws_iam_policy_document.github_frontend.json
    }

    # Backend deployment role
    backend_deploy = {
      role_name = "github-actions-backend-deploy"
      role_description = "IAM role for GitHub Actions backend deployment"
      max_session_duration = 900
      oidc_conditions = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = ["repo:my-org/my-backend:*"]
        },
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:ref"
          values   = ["refs/heads/main", "refs/heads/develop"]
        }
      ]
      policy_json = data.aws_iam_policy_document.github_backend.json
    }
  }
}

# =============================================================================
# GitLab CI OIDC Configuration
# =============================================================================

module "gitlab_ci_oidc" {
  source  = "../.."
  version = "~> 2.0"

  provider_url    = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = ["b0e1b1272430e6d1c3f2c55a74e2b12c7a0f234a"]

  roles = {
    # GitLab CI deployment role
    ci_deploy = {
      role_name = "gitlab-ci-deploy"
      role_description = "IAM role for GitLab CI/CD deployments"
      max_session_duration = 900
      oidc_conditions = [
        {
          test     = "StringEquals"
          variable = "gitlab.com:aud"
          values   = ["https://gitlab.com"]
        },
        {
          test     = "StringLike"
          variable = "gitlab.com:sub"
          values   = ["project_path:my-group/my-project:*"]
        }
      ]
      policy_json = data.aws_iam_policy_document.gitlab_ci.json
    }
  }
}

# =============================================================================
# Policy Documents
# =============================================================================

# Terraform Cloud Production Policy
data "aws_iam_policy_document" "tfc_production" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "ec2:*",
      "rds:*",
      "lambda:*",
      "apigateway:*",
      "cloudfront:*",
      "route53:*"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = ["iam:*", "organizations:*"]
    resources = ["*"]
  }
}

# Terraform Cloud Staging Policy
data "aws_iam_policy_document" "tfc_staging" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "ec2:*",
      "lambda:*",
      "apigateway:*"
    ]
    resources = ["arn:aws:s3:::staging-*", "arn:aws:s3:::staging-*/*", "arn:aws:ec2:*:*:instance/*", "arn:aws:lambda:*:*:function:staging-*"]
  }
}

# GitHub Actions Frontend Policy
data "aws_iam_policy_document" "github_frontend" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      "arn:aws:s3:::my-frontend-bucket",
      "arn:aws:s3:::my-frontend-bucket/*",
      "arn:aws:cloudfront::*:distribution/E1A2B3C4D5E6F7"
    ]
  }
}

# GitHub Actions Backend Policy
data "aws_iam_policy_document" "github_backend" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:PublishVersion",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:POST",
      "apigateway:DELETE"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:my-backend-*",
      "arn:aws:apigateway:*::/restapis/*"
    ]
  }
}

# GitLab CI Policy
data "aws_iam_policy_document" "gitlab_ci" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }
}

# =============================================================================
# Outputs
# =============================================================================

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