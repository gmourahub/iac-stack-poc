output "deploy_role_arns" {
  description = "Deploy role ARN per target environment, for the CI workflow's role-to-assume."
  value       = { for target, role in aws_iam_role.deploy : target => role.arn }
}

output "ecr_repository_urls" {
  description = "ECR repository URL per application."
  value       = { for app, repo in aws_ecr_repository.app : app => repo.repository_url }
}
