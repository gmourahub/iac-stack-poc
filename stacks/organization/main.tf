# Existing organization: adopt it with an `import` block (README). Both lists are authoritative: anything
# enabled in AWS but missing here is disabled on apply, so reconcile the tfvars before the first plan.
resource "aws_organizations_organization" "main" {
  feature_set                   = "ALL"
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "main" {
  for_each = local.organizational_units

  name      = each.key
  parent_id = aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_account" "main" {
  for_each = var.accounts

  name                       = each.key
  email                      = each.value.email
  parent_id                  = aws_organizations_organizational_unit.main[each.value.organizational_unit].id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  close_on_deletion          = false

  lifecycle {
    prevent_destroy = true
    # AWS does not return role_name after creation; changing it would force a new account.
    ignore_changes = [role_name]
  }
}
