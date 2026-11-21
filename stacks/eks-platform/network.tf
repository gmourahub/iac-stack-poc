# Integration Registry lookup (ARCHITECTURE.md): network publishes these keys in the same account.
data "aws_ssm_parameter" "vpc_id" {
  name = "/platform/${var.environment}/network/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/platform/${var.environment}/network/private_subnet_ids"
}
