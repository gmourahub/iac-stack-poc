resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# One role per deploy target. The trust is pinned to one repository AND one GitHub environment,
# so a workflow job can only get the role of the environment it runs in (and its protection rules).
data "aws_iam_policy_document" "deploy_trust" {
  for_each = var.deploy_targets

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:environment:${each.value}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  for_each = var.deploy_targets

  name                 = "acme-${var.environment}-deploy-${each.key}"
  description          = "GitHub Actions deploy role for target environment ${each.key}"
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust[each.key].json
  max_session_duration = 3600
}

# The deploy role only hops into the target account's role named acme-<target>-deploy, inside the org.
# No account IDs here: the role name carries the target, aws:ResourceOrgID keeps it inside the org.
data "aws_iam_policy_document" "deploy" {
  for_each = var.deploy_targets

  statement {
    sid       = "AssumeTargetDeployRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = ["arn:aws:iam::*:role/acme-${each.key}-deploy"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceOrgID"
      values   = [var.organization_id]
    }
  }
}

resource "aws_iam_role_policy" "deploy" {
  for_each = var.deploy_targets

  name   = "assume-target-deploy-role"
  role   = aws_iam_role.deploy[each.key].id
  policy = data.aws_iam_policy_document.deploy[each.key].json
}
