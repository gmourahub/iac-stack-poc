output "cache_port" {
  description = "Port of the cache."
  value       = module.cache.port
}

output "cache_primary_endpoint" {
  description = "Primary (write) endpoint of the cache."
  value       = module.cache.primary_endpoint
}

output "cache_reader_endpoint" {
  description = "Reader endpoint of the cache."
  value       = module.cache.reader_endpoint
}

output "commands_queue_url" {
  description = "URL of the queue the app consumes commands from."
  value       = module.commands_queue.queue_url
}

output "database_address" {
  description = "Hostname of the PostgreSQL database."
  value       = module.database.address
}

output "database_name" {
  description = "Name of the application database."
  value       = var.service
}

output "database_port" {
  description = "Port of the PostgreSQL database."
  value       = module.database.port
}

output "database_secret_arn" {
  description = "ARN of the DB master credentials secret (the ARN, not the secret). Operator/migration use only; the app pod has no access."
  value       = module.database.master_user_secret_arn
}

output "events_topic_arn" {
  description = "ARN of the SNS topic the app publishes its domain events to."
  value       = module.events_topic.topic_arn
}

output "role_arn" {
  description = "IAM role the app's service account assumes through EKS Pod Identity."
  value       = module.workload_identity.role_arn
}
