output "state_bucket" {
  description = "S3 bucket holding Terraform state (use in backend blocks)."
  value       = aws_s3_bucket.tfstate.bucket
}

output "github_plan_role_arn" {
  description = "Role for GitHub Actions on pull requests (store as repo variable AWS_PLAN_ROLE_ARN)."
  value       = aws_iam_role.github_plan.arn
}

output "github_deploy_role_arn" {
  description = "Role for GitHub Actions on main (store as repo variable AWS_DEPLOY_ROLE_ARN)."
  value       = aws_iam_role.github_deploy.arn
}

output "region" {
  value = var.region
}
