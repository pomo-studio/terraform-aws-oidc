# Complete OIDC Example

This example demonstrates a full OIDC setup for multiple identity providers:

1. **Terraform Cloud** - For infrastructure deployment
2. **GitHub Actions** - For CI/CD pipelines
3. **GitLab CI** - For GitLab CI/CD deployments

## Architecture

The example creates three separate OIDC providers, each with their own IAM roles and trust policies:

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Terraform Cloud │    │ GitHub Actions  │    │    GitLab CI    │
│   OIDC Provider │    │   OIDC Provider │    │   OIDC Provider │
└────────┬────────┘    └────────┬────────┘    └────────┬────────┘
         │                      │                      │
         ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Production Role │    │ Frontend Deploy │    │   CI Deploy     │
│   Staging Role  │    │  Backend Deploy │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Usage

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Review the plan**:

   ```bash
   terraform plan
   ```

3. **Apply the configuration**:

   ```bash
   terraform apply
   ```

## Configuration Details

### Terraform Cloud OIDC

**Provider URL**: `https://app.terraform.io`
**Client ID**: `aws.workload.identity`
**Thumbprint**: `9e99a48a9960b14926bb7f3b02e22da2b0ab7280`

**Roles**:

- `production` - Full access to production resources (except IAM/Organizations)
- `staging` - Limited access to staging resources

**Trust Conditions**:

- `app.terraform.io:aud = "aws.workload.identity"`
- `app.terraform.io:sub` matches workspace patterns

### GitHub Actions OIDC

**Provider URL**: `https://token.actions.githubusercontent.com`
**Client ID**: `sts.amazonaws.com`
**Thumbprints**: `6938fd4d98bab03faadb97b34396831e3780aea1`, `1c58a3a8518e8759bf075b76b750d4f2df264fcd`

**Roles**:

- `frontend_deploy` - S3 and CloudFront access for frontend deployments
- `backend_deploy` - Lambda and API Gateway access for backend deployments

**Trust Conditions**:

- `token.actions.githubusercontent.com:aud = "sts.amazonaws.com"`
- Repository and branch restrictions

### GitLab CI OIDC

**Provider URL**: `https://gitlab.com`
**Client ID**: `https://gitlab.com`
**Thumbprint**: `b0e1b1272430e6d1c3f2c55a74e2b12c7a0f234a`

**Roles**:

- `ci_deploy` - ECR and ECS access for container deployments

**Trust Conditions**:

- `gitlab.com:aud = "https://gitlab.com"`
- Project path restrictions

## Policy Examples

Each role includes example IAM policies demonstrating:

- Least privilege access patterns
- Resource-level permissions
- Service-specific actions

## Outputs

After applying, you'll get:

- OIDC provider ARNs for each identity provider
- IAM role ARNs for each configured role
- Ready-to-use role configurations for your CI/CD pipelines

## Customization

1. **Update trust conditions** to match your organization, repository, or workspace patterns
2. **Adjust IAM policies** to match your specific resource permissions
3. **Add more roles** for different environments or deployment scenarios
4. **Modify session durations** based on your security requirements

## Security Notes

- Always use the latest thumbprints for OIDC providers
- Restrict trust conditions to specific repositories, branches, or workspaces
- Use separate roles for different environments (production, staging, development)
- Regularly review and update IAM policies
