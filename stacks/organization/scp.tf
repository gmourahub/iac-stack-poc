# Baseline guardrail for every member account (infra-governance: platform control, same in every environment).
data "aws_iam_policy_document" "baseline" {
  statement {
    sid       = "DenyLeaveOrganization"
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyDisableCloudTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:PutEventSelectors",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyDisableGuardDuty"
    effect = "Deny"
    actions = [
      "guardduty:DeleteDetector",
      "guardduty:DeleteMembers",
      "guardduty:DisassociateFromAdministratorAccount",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:DisassociateMembers",
      "guardduty:StopMonitoringMembers",
      "guardduty:UpdateDetector",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyOutsideAllowedRegions"
    effect = "Deny"
    # Global services are served from us-east-1 and must stay reachable from any region.
    not_actions = [
      "account:*",
      "budgets:*",
      "ce:*",
      "cloudfront:*",
      "globalaccelerator:*",
      "health:*",
      "iam:*",
      "organizations:*",
      "route53:*",
      "route53domains:*",
      "shield:*",
      "sts:*",
      "support:*",
      "trustedadvisor:*",
      "waf:*",
      "wafv2:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_organizations_policy" "baseline" {
  name        = "acme-baseline"
  description = "Deny leaving the org, disabling CloudTrail/GuardDuty and using non-approved regions."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.baseline.minified_json

  # No attribute links it to the org, but CreatePolicy fails until the org exists with SCPs enabled.
  depends_on = [aws_organizations_organization.main]
}

# Attached to every OU rather than the root: SCPs never apply to the management account anyway, and
# per-OU attachment lets a future OU opt out explicitly instead of inheriting it silently.
resource "aws_organizations_policy_attachment" "baseline" {
  for_each = aws_organizations_organizational_unit.main

  policy_id = aws_organizations_policy.baseline.id
  target_id = each.value.id
}

moved {
  from = aws_organizations_policy.workloads_baseline
  to   = aws_organizations_policy.baseline
}

moved {
  from = aws_organizations_policy_attachment.workloads_baseline
  to   = aws_organizations_policy_attachment.baseline["Workloads"]
}
