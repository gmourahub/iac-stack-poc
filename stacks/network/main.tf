module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.8"

  name = "acme-${var.environment}"
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.data_subnets

  database_subnet_suffix = "data"
  # Each app creates its own DB subnet group from the data subnets (modules/app-database).
  create_database_subnet_group = false

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet discovery for the AWS Load Balancer Controller on EKS.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Standalone flow-log module: in-module flow logs are deprecated in vpc v6 and removed in v7.
module "flow_log" {
  source  = "terraform-aws-modules/vpc/aws//modules/flow-log"
  version = "~> 6.8"

  name   = "acme-${var.environment}"
  vpc_id = module.vpc.vpc_id

  cloudwatch_log_group_retention_in_days = var.flow_log_retention_days
  cloudwatch_log_group_kms_key_id        = aws_kms_key.flow_log.arn
}
