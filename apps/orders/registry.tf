# Integration Registry (ARCHITECTURE.md): values published by the network and eks-platform stacks.
# insecure_value: these are plain String/StringList identifiers; `value` is always marked sensitive
# and would taint every module input and for_each derived from it.
data "aws_ssm_parameter" "vpc_id" {
  name = "/platform/${var.environment}/network/vpc_id"
}

data "aws_ssm_parameter" "data_subnet_ids" {
  name = "/platform/${var.environment}/network/data_subnet_ids"
}

data "aws_ssm_parameter" "cluster_name" {
  name = "/platform/${var.environment}/eks/cluster_name"
}

data "aws_ssm_parameter" "node_security_group_id" {
  name = "/platform/${var.environment}/eks/node_security_group_id"
}
