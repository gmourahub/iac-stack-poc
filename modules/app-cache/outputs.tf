output "port" {
  description = "Cache port."
  value       = aws_elasticache_replication_group.this.port
}

output "primary_endpoint" {
  description = "Primary (write) endpoint address."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint address."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "security_group_id" {
  description = "Security group attached to the cache."
  value       = aws_security_group.this.id
}
