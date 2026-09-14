# Basic OIDC Example

Shows the module creating an OIDC provider and IAM roles for Terraform Cloud and GitHub Actions.

## What it creates

- One `aws_iam_openid_connect_provider` for Terraform Cloud, with a `terraform-cloud-staging` role and inline permissions.
- One `aws_iam_openid_connect_provider` for GitHub Actions, with a `github-actions-my-app` role and inline permissions.
- Two `aws_iam_role_policy` documents built from example S3 and deploy policies.
- Users, repositories, and conditions in the example are placeholders. Replace them with your own.

## Before you start

- AWS provider, region `us-east-1`. Real credentials are required to apply.
- Uses the published registry module `pomo-studio/oidc/aws` at version `~> 2.0`.
- No resources need to exist first. Existing providers with the same URL will conflict.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

## Clean up

```bash
terraform destroy
```
