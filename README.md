# terraform-aws-oidc

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-oidc/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-oidc/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/oidc/aws)

- [Changelog](CHANGELOG.md)

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.64.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_id_list"></a> [client\_id\_list](#input\_client\_id\_list) | List of client IDs (audiences) for the OIDC provider | `list(string)` | n/a | yes |
| <a name="input_provider_url"></a> [provider\_url](#input\_provider\_url) | OIDC provider URL (e.g. https://app.terraform.io) | `string` | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | Map of IAM roles to create with OIDC trust policies | <pre>map(object({<br/>    role_name = string<br/>    oidc_conditions = list(object({<br/>      test     = string<br/>      variable = string<br/>      values   = list(string)<br/>    }))<br/>    policy_json = string<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_thumbprint_list"></a> [thumbprint\_list](#input\_thumbprint\_list) | List of server certificate thumbprints for the OIDC provider | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_provider_arn"></a> [provider\_arn](#output\_provider\_arn) | ARN of the OIDC identity provider |
| <a name="output_role_arns"></a> [role\_arns](#output\_role\_arns) | Map of role keys to IAM role ARNs |
| <a name="output_role_names"></a> [role\_names](#output\_role\_names) | Map of role keys to IAM role names |
<!-- END_TF_DOCS -->

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

## Examples

- [`examples/basic`](examples/basic/) — GitHub Actions OIDC for a single repo
- [`examples/complete`](examples/complete/) — Terraform Cloud + GitHub Actions, multiple roles

## License

MIT
