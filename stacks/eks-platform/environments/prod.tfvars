region      = "us-east-1"
environment = "prod"
service     = "eks-platform"
owner       = "platform-team"
cost_center = "platform"

kubernetes_version = "1.35"

# Example value: the platform admin role in this account (e.g. an IAM Identity Center permission set role).
admin_role_arn = "arn:aws:iam::333333333333:role/acme-prod-platform-admin"

# Private endpoint only: operators and CI reach the API from inside the VPC.
endpoint_public_access_cidrs = []

node_instance_types = ["m7i.xlarge"]
node_min_size       = 3
node_max_size       = 9
node_desired_size   = 3
