output "account_ids" {
  description = "Account ID per account name, used to configure CI credentials per environment."
  value       = { for name, account in aws_organizations_account.main : name => account.id }
}

output "organization_id" {
  description = "Organization ID (o-...), the value for aws:PrincipalOrgID conditions in other stacks."
  value       = aws_organizations_organization.main.id
}

output "organizational_unit_ids" {
  description = "OU ID per OU name."
  value       = { for name, ou in aws_organizations_organizational_unit.main : name => ou.id }
}
