# terraform-aws-oidc

Terraform module for the full OIDC lifecycle on AWS — creates an identity provider and any number of IAM roles with scoped trust policies and permissions.

- One module call provisions both the identity provider and all its IAM roles — no orphaned providers
- Works with Terraform Cloud, GitHub Actions, or any OIDC-compliant CI system
- Inline policies per role — no shared managed policies, no 10-policy-per-role limit
- Flexible condition syntax — any `StringEquals`, `StringLike`, `ForAnyValue` combination
- Eliminates static IAM credentials entirely — no access keys to rotate or leak

**Registry**: `pomo-studio/oidc/aws`

## Usage

### Terraform Cloud

```hcl
module "tfc_oidc" {
  source  = "pomo-studio/oidc/aws"
  version = "~> 2.0"

  provider_url    = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  roles = {
    staging = {
      role_name = "terraform-cloud-staging"
      oidc_conditions = [
        { test = "StringEquals", variable = "app.terraform.io:aud", values = ["aws.workload.identity"] },
        { test = "StringLike",   variable = "app.terraform.io:sub", values = ["organization:my-org:project:*:workspace:staging:run_phase:*"] }
      ]
      policy_json = data.aws_iam_policy_document.staging.json
    }
    production = {
      role_name = "terraform-cloud-production"
      oidc_conditions = [
        { test = "StringEquals", variable = "app.terraform.io:aud", values = ["aws.workload.identity"] },
        { test = "StringLike",   variable = "app.terraform.io:sub", values = ["organization:my-org:project:*:workspace:production:run_phase:*"] }
      ]
      policy_json = data.aws_iam_policy_document.production.json
    }
  }

  tags = { ManagedBy = "terraform" }
}
```

### GitHub Actions

```hcl
module "github_oidc" {
  source  = "pomo-studio/oidc/aws"
  version = "~> 2.0"

  provider_url    = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  roles = {
    my-app = {
      role_name = "github-actions-my-app"
      oidc_conditions = [
        { test = "StringEquals", variable = "token.actions.githubusercontent.com:aud", values = ["sts.amazonaws.com"] },
        { test = "StringLike",   variable = "token.actions.githubusercontent.com:sub", values = ["repo:my-org/my-app:*"] }
      ]
      policy_json = data.aws_iam_policy_document.deploy.json
    }
  }
}
```

## Variables

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `provider_url` | `string` | yes | OIDC provider URL |
| `client_id_list` | `list(string)` | yes | Audience values for the provider |
| `thumbprint_list` | `list(string)` | yes | Server certificate thumbprints |
| `roles` | `map(object)` | no | IAM roles to create (see below) |
| `tags` | `map(string)` | no | Tags for all resources |

### `roles` object

| Field | Type | Description |
|-------|------|-------------|
| `role_name` | `string` | IAM role name |
| `oidc_conditions` | `list(object)` | Trust policy conditions (`test`, `variable`, `values`) |
| `policy_json` | `string` | IAM permissions policy as JSON |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `provider_arn` | `string` | ARN of the OIDC identity provider |
| `role_arns` | `map(string)` | Map of role keys to IAM role ARNs |
| `role_names` | `map(string)` | Map of role keys to IAM role names |

## What it creates

Per module call:
- 1 `aws_iam_openid_connect_provider`
- N `aws_iam_role` (one per key in `roles`)
- N `aws_iam_role_policy` (inline permissions per role)

## Design decisions

**One provider per module call** — OIDC providers and their roles are a logical unit. Grouping them avoids orphaned providers and makes the trust chain explicit.

**Inline policies over managed policies** — each role gets a dedicated inline policy. This keeps permissions self-contained and avoids the 10-managed-policy limit per role.

**Flexible conditions** — the `oidc_conditions` list supports any combination of `StringEquals`, `StringLike`, `ForAnyValue`, etc. No assumptions about provider-specific claim formats.

## Migrating from v1.0.0

v1.0.0 created individual roles (one module call per role, provider managed externally). v2.0.0 manages the provider and uses `for_each` on roles.

Use `moved` blocks to migrate without destroying resources:

```hcl
# Provider — from inline resource to module
moved {
  from = aws_iam_openid_connect_provider.tfc
  to   = module.tfc_oidc.aws_iam_openid_connect_provider.this
}

# Roles — from per-key module to single module with for_each
moved {
  from = module.tfc_role["staging"].aws_iam_role.this
  to   = module.tfc_oidc.aws_iam_role.this["staging"]
}
moved {
  from = module.tfc_role["staging"].aws_iam_role_policy.this
  to   = module.tfc_oidc.aws_iam_role_policy.this["staging"]
}
```

Remove `moved` blocks after the first successful apply.

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.5.0` |
| AWS provider | `~> 5.0` |

## License

MIT
