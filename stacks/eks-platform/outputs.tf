# Consumers read the SSM registry keys (registry.tf), not these outputs; outputs are for operators.
output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "node_security_group_id" {
  description = "Security group shared by the managed nodes."
  value       = module.eks.node_security_group_id
}
