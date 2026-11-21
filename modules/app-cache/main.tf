resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-cache"
  description = "Cache access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

# No egress rule: the cache only answers inbound connections.
resource "aws_vpc_security_group_ingress_rule" "cache" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  description                  = "Cache from ${each.key}"
  tags                         = var.tags
}

locals {
  # Failover and Multi-AZ need at least one replica.
  ha = var.num_cache_clusters > 1
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = "Cache for ${var.name}"
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  automatic_failover_enabled = local.ha
  multi_az_enabled           = local.ha

  tags = var.tags
}
