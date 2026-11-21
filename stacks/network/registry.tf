# Integration Registry (ARCHITECTURE.md). These names are a public API: change them only with expand/contract.
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/platform/${var.environment}/network/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "vpc_cidr" {
  name  = "/platform/${var.environment}/network/vpc_cidr"
  type  = "String"
  value = module.vpc.vpc_cidr_block
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/platform/${var.environment}/network/private_subnet_ids"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}

resource "aws_ssm_parameter" "data_subnet_ids" {
  name  = "/platform/${var.environment}/network/data_subnet_ids"
  type  = "StringList"
  value = join(",", module.vpc.database_subnets)
}
