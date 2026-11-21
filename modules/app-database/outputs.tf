output "address" {
  description = "Hostname of the instance."
  value       = aws_db_instance.this.address
}

output "db_instance_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.identifier
}

output "db_resource_id" {
  description = "Instance resource ID (db-...), used in rds-db:connect ARNs for IAM database authentication."
  value       = aws_db_instance.this.resource_id
}

output "endpoint" {
  description = "Connection endpoint in address:port form."
  value       = aws_db_instance.this.endpoint
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials (operators and migration jobs only, never app pods)."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "security_group_id" {
  description = "Security group attached to the instance."
  value       = aws_security_group.this.id
}
