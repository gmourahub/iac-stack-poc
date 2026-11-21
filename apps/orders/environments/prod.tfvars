# No secrets here: this file is committed.
environment = "prod"
region      = "us-east-1"
service     = "orders"
owner       = "team-orders"
cost_center = "orders"

db_engine_version        = "17"
db_instance_class        = "db.r7g.large"
db_allocated_storage     = 100
db_max_allocated_storage = 500
db_multi_az              = true
db_backup_retention_days = 14
db_deletion_protection   = true

cache_engine_version = "8.0"
cache_node_type      = "cache.r7g.large"
cache_num_nodes      = 2
