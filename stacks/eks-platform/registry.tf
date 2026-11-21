# Integration Registry (ARCHITECTURE.md). These names are a public API: change them only with expand/contract.
resource "aws_ssm_parameter" "cluster_name" {
  name  = "/platform/${var.environment}/eks/cluster_name"
  type  = "String"
  value = module.eks.cluster_name
}

resource "aws_ssm_parameter" "node_security_group_id" {
  name  = "/platform/${var.environment}/eks/node_security_group_id"
  type  = "String"
  value = module.eks.node_security_group_id
}
