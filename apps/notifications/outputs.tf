output "events_queue_url" {
  description = "URL of the queue that receives orders and payments events."
  value       = module.events_queue.queue_url
}

output "role_arn" {
  description = "IAM role the app's service account assumes through EKS Pod Identity."
  value       = module.workload_identity.role_arn
}

output "templates_bucket_name" {
  description = "Bucket holding the notification templates (objects under the templates/ prefix)."
  value       = module.templates_bucket.bucket_name
}
