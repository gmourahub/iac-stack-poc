output "deploy_role_arn" {
  description = "ARN of acme-<env>-deploy; goes to the AWS_TARGET_ROLE_ARN variable of the matching GitHub environment."
  value       = aws_iam_role.deploy.arn
}

output "deploy_boundary_arn" {
  description = "ARN of the permissions boundary attached to the deploy role."
  value       = aws_iam_policy.deploy_boundary.arn
}
