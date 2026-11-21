# No secrets here: this file is committed.
environment = "staging"
region      = "us-east-1"
service     = "orders"
owner       = "team-orders"
cost_center = "orders"

db_engine_version        = "17"
db_instance_class        = "db.t4g.medium"
db_allocated_storage     = 20
db_max_allocated_storage = 100
db_multi_az              = false
db_backup_retention_days = 7
db_deletion_protection   = true

cache_engine_version = "8.0"
cache_node_type      = "cache.t4g.small"
cache_num_nodes      = 1
