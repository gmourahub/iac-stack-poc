mock_provider "aws" {}

variables {
  name                       = "orders-staging"
  vpc_id                     = "vpc-0123456789abcdef0"
  subnet_ids                 = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  allowed_security_group_ids = { eks_nodes = "sg-0eks000000000000a" }
  engine_version             = "8.0"
  node_type                  = "cache.t4g.small"
  num_cache_clusters         = 1
}

run "single_node_valkey_encrypted_without_failover" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.this.engine == "valkey"
    error_message = "Engine must default to valkey."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled && aws_elasticache_replication_group.this.at_rest_encryption_enabled
    error_message = "Encryption in transit and at rest must be on."
  }

  assert {
    condition     = !aws_elasticache_replication_group.this.automatic_failover_enabled && !aws_elasticache_replication_group.this.multi_az_enabled
    error_message = "A single node cannot fail over."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.cache["eks_nodes"].from_port == 6379 && aws_vpc_security_group_ingress_rule.cache["eks_nodes"].referenced_security_group_id == "sg-0eks000000000000a"
    error_message = "Ingress must be 6379 from the allowed security group."
  }
}

run "multi_node_enables_failover" {
  command = plan

  variables {
    num_cache_clusters = 2
  }

  assert {
    condition     = aws_elasticache_replication_group.this.automatic_failover_enabled && aws_elasticache_replication_group.this.multi_az_enabled
    error_message = "More than one node must enable automatic failover and Multi-AZ."
  }
}

run "rejects_unknown_engine" {
  command = plan

  variables {
    engine = "memcached"
  }

  expect_failures = [var.engine]
}
