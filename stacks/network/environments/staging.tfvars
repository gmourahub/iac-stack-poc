region      = "us-east-1"
environment = "staging"
service     = "network"
owner       = "platform-team"
cost_center = "platform"

vpc_cidr           = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
single_nat_gateway = true

flow_log_retention_days = 30
