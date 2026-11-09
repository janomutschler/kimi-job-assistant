# infra/bootstrap

One-time foundation that everything else builds on. Applied **manually from a laptop**,
because CI can't authenticate to AWS until this exists.

| Resource | Purpose |
|---|---|
| S3 bucket `kimi-tfstate-<account>` | Terraform state for bootstrap and app (versioned, encrypted, TLS-only, S3-native locking) |
| GitHub OIDC provider | GitHub Actions gets short-lived AWS credentials, no stored keys |
| Role `kimi-github-plan` | Pull requests: read-only + state access, for `terraform plan` |
| Role `kimi-github-deploy` | `main` only: PowerUserAccess + IAM limited to `kimi-app-*` roles/policies |
| Budget `kimi-monthly` | Email alerts at 80 % actual / 100 % forecasted spend |

## Prerequisites

- Terraform >= 1.10 and AWS CLI >= 2.32 (`aws login`)
- An AWS account that allows IAM identity providers. Accounts in AWS's simplified "new experience"
  block them via service control policies until advanced features are activated.

## Apply (bucket already exists)

```bash
aws login --profile kimi --region eu-north-1
cd infra/bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in your email
cp backend.hcl.example backend.hcl             # fill in your account ID
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## First-time setup (fresh account)

The state bucket can't store its own state before it exists:

1. Comment out the block in `backend.tf`, then `terraform init` and `terraform apply` (local state).
2. Uncomment it, create `backend.hcl`, and run `terraform init -migrate-state -backend-config=backend.hcl`.
3. Verify with `terraform plan` ("No changes"), then delete the local `terraform.tfstate*` files.

## Outputs → GitHub

Store these as repository **variables** (Settings → Secrets and variables → Actions → Variables).
None are secret: a role ARN is useless without a valid OIDC token from this repository.

| Output | GitHub variable |
|---|---|
| `region` | `AWS_REGION` |
| `github_plan_role_arn` | `AWS_PLAN_ROLE_ARN` |
| `github_deploy_role_arn` | `AWS_DEPLOY_ROLE_ARN` |
| `state_bucket` | `TF_STATE_BUCKET` |

## Design notes

- **Plan vs deploy role:** PRs can only read; only code merged to protected `main` can change infrastructure.
- **Why not AdministratorAccess for deploy:** PowerUserAccess excludes IAM; the scoped policy allows
  managing only the project's own `kimi-app-*` roles. Known gap: a role created under that prefix could
  be given broad permissions. That's acceptable here because only reviewed code on `main` can assume the
  deploy role; tightening with a permissions boundary is a later improvement.
- **Partial backend config:** backend blocks can't use variables, so account-specific values live in a
  git-ignored `backend.hcl`; CI passes them via `-backend-config` flags.
