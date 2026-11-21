# No secrets here: this file is committed.
environment = "prod"
region      = "us-east-1"
service     = "payments"
owner       = "team-payments"
cost_center = "payments"

db_engine_version        = "17"
db_instance_class        = "db.r7g.large"
db_allocated_storage     = 100
db_max_allocated_storage = 500
db_multi_az              = true
db_backup_retention_days = 14
db_deletion_protection   = true
