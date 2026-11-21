region      = "us-east-1"
environment = "management"
service     = "organization"
owner       = "platform-team"
cost_center = "platform"

allowed_regions = ["us-east-1", "us-west-2"]

# Authoritative lists: reconcile with
#   aws organizations list-aws-service-access-for-organization
#   aws organizations list-roots   (Roots[0].PolicyTypes with Status ENABLED)
# before the first plan against an existing organization.
aws_service_access_principals = [
  "account.amazonaws.com",
  "cloudtrail.amazonaws.com",
  "config.amazonaws.com",
  "guardduty.amazonaws.com",
  "member.org.stacksets.cloudformation.amazonaws.com",
  "sso.amazonaws.com",
]

enabled_policy_types = [
  "RESOURCE_CONTROL_POLICY",
  "SERVICE_CONTROL_POLICY",
  "TAG_POLICY",
]

accounts = {
  acme-shared = {
    email               = "aws+acme-shared@example.com"
    organizational_unit = "Infrastructure"
  }
  acme-staging = {
    email               = "aws+acme-staging@example.com"
    organizational_unit = "Workloads"
  }
  acme-prod = {
    email               = "aws+acme-prod@example.com"
    organizational_unit = "Workloads"
  }
}
