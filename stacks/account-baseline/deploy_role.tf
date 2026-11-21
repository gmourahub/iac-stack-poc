data "aws_caller_identity" "current" {}

locals {
  deploy_role_name     = "acme-${var.environment}-deploy"
  deploy_boundary_name = "acme-${var.environment}-deploy-boundary"
  # Created by stacks/shared-services (acme-<shared env>-deploy-<target>); trusted by ARN pattern, so it may not exist yet.
  source_role_arn = "arn:aws:iam::${var.shared_account_id}:role/acme-shared-deploy-${var.environment}"
}

# Trust the shared account, narrowed to the one deploy role for this environment via aws:PrincipalArn.
# A condition (not a role principal) keeps working if that role is recreated and does not need it to exist.
data "aws_iam_policy_document" "deploy_trust" {
  statement {
    effect = "Allow"
    # sts:TagSession: configure-aws-credentials tags chained sessions (repo, workflow, actor, commit).
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.shared_account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [local.source_role_arn]
    }
  }
}

# Terraform deploys create VPCs, EKS, RDS, ElastiCache, SNS/SQS, S3, KMS and IAM roles for workloads.
# Scoping that to a hand-written action list breaks on every new resource type, so the role gets
# AdministratorAccess and the boundary below removes what a pipeline must never do. The real controls are:
# only the pipeline (GitHub environment + repo pinned in the OIDC trust) reaches this role, every change is a reviewed commit.
data "aws_iam_policy_document" "deploy_boundary" {
  statement {
    sid       = "AllowEverythingNotDenied"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyLongLivedCredentials"
    effect = "Deny"
    actions = [
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:CreateUser",
      "iam:UpdateLoginProfile",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyOrganizationAndAccountChanges"
    effect = "Deny"
    actions = [
      "account:*",
      "organizations:*",
    ]
    resources = ["*"]
  }

  # The guardrails in guardrails.tf are owned by this stack, applied by an admin, not by the pipeline.
  statement {
    sid    = "DenyWeakeningAccountGuardrails"
    effect = "Deny"
    actions = [
      "ec2:DisableEbsEncryptionByDefault",
      "s3:PutAccountPublicAccessBlock",
    ]
    resources = ["*"]
  }

  # Without this the pipeline could edit its own role or boundary and lift every deny above.
  statement {
    sid    = "DenySelfModification"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
      "iam:SetDefaultPolicyVersion",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.deploy_role_name}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.deploy_boundary_name}",
    ]
  }
}

# Allow * is the point of a boundary: it caps permissions, the denies are what it adds.
#trivy:ignore:AVD-AWS-0057
resource "aws_iam_policy" "deploy_boundary" {
  name        = local.deploy_boundary_name
  description = "Permissions boundary of ${local.deploy_role_name}: no IAM users/keys, no org/account changes, no guardrail or self changes."
  policy      = data.aws_iam_policy_document.deploy_boundary.json
}

resource "aws_iam_role" "deploy" {
  name                 = local.deploy_role_name
  description          = "Terraform deploy role, assumed by acme-shared-deploy-${var.environment} from the CI"
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust.json
  permissions_boundary = aws_iam_policy.deploy_boundary.arn
  max_session_duration = var.deploy_role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "deploy_admin" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
