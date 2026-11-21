# Consumers read the SSM registry keys (registry.tf), not these outputs; outputs are for operators.
output "data_subnet_ids" {
  description = "Data (database) subnet IDs."
  value       = module.vpc.database_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnets
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}
