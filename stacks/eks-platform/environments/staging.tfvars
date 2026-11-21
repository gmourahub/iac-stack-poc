region      = "us-east-1"
environment = "staging"
service     = "eks-platform"
owner       = "platform-team"
cost_center = "platform"

kubernetes_version = "1.35"

# Example value: the platform admin role in this account (e.g. an IAM Identity Center permission set role).
admin_role_arn = "arn:aws:iam::222222222222:role/acme-staging-platform-admin"

# Office/VPN egress allowed to reach the public endpoint. Empty list = private endpoint only.
endpoint_public_access_cidrs = ["203.0.113.0/24"]

node_instance_types = ["m7i.large"]
node_min_size       = 2
node_max_size       = 4
node_desired_size   = 2
