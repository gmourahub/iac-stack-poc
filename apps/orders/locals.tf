locals {
  name = "${var.service}-${var.environment}"

  vpc_id          = data.aws_ssm_parameter.vpc_id.insecure_value
  data_subnet_ids = split(",", data.aws_ssm_parameter.data_subnet_ids.insecure_value)
  cluster_name    = data.aws_ssm_parameter.cluster_name.insecure_value

  # shortcut: every pod on the EKS nodes can reach the DB and cache; switch to Security Groups for Pods to isolate per app.
  allowed_security_group_ids = {
    eks_nodes = data.aws_ssm_parameter.node_security_group_id.insecure_value
  }
}
