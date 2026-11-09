provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      project    = "kimi"
      component  = "bootstrap"
      managed-by = "terraform"
      repo       = "${var.github_owner}/${var.github_repo}"
    }
  }
}

data "aws_caller_identity" "current" {}
