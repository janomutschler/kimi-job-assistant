variable "region" {
  description = "AWS region for all project resources."
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile used to apply the bootstrap (set via aws login)."
  type        = string
  default     = "kimi"
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "Repository name allowed to assume the CI roles."
  type        = string
}

variable "budget_limit_usd" {
  description = "Monthly cost budget in USD; alerts at 80% actual and 100% forecast."
  type        = number
  default     = 20
}

variable "budget_email" {
  description = "Email address for budget alerts (kept out of git via terraform.tfvars)."
  type        = string
}
