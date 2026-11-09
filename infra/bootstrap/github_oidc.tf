# Lets GitHub Actions authenticate to AWS with short-lived tokens instead of stored access keys.
# Two roles: "plan" (read-only, any pull request) and "deploy" (main branch only).

locals {
  github_oidc_host = "token.actions.githubusercontent.com"
  repo             = "${var.github_owner}/${var.github_repo}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.github_oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
}

# ---------- Plan role: pull requests, read-only ----------

data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:sub"
      values   = ["repo:${local.repo}:pull_request"]
    }
  }
}

resource "aws_iam_role" "github_plan" {
  name                 = "kimi-github-plan"
  description          = "Assumed by GitHub Actions on pull requests to run terraform plan."
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------- Deploy role: main branch only ----------

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:sub"
      values   = ["repo:${local.repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name                 = "kimi-github-deploy"
  description          = "Assumed by GitHub Actions on main to apply infrastructure and deploy."
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust.json
  max_session_duration = 3600
}

# Broad service access, but no general IAM rights.
resource "aws_iam_role_policy_attachment" "deploy_poweruser" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM only for the project's own roles/policies (Lambda execution roles etc.), all prefixed "kimi-app-".
data "aws_iam_policy_document" "deploy_iam_scoped" {
  statement {
    sid = "ManageProjectRolesAndPolicies"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PassRole",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kimi-app-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/kimi-app-*",
    ]
  }

  statement {
    sid       = "CreateServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy_iam_scoped" {
  name   = "kimi-deploy-iam-scoped"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.deploy_iam_scoped.json
}

# ---------- Both roles: read/write Terraform state ----------

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }

  statement {
    sid       = "ReadWriteStateAndLocks"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/*"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "kimi-tfstate-access"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role_policy" "deploy_state" {
  name   = "kimi-tfstate-access"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.state_access.json
}
