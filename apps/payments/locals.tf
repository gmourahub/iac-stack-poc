locals {
  name = "${var.service}-${var.environment}"

  vpc_id          = data.aws_ssm_parameter.vpc_id.insecure_value
  data_subnet_ids = split(",", data.aws_ssm_parameter.data_subnet_ids.insecure_value)
  cluster_name    = data.aws_ssm_parameter.cluster_name.insecure_value

  # shortcut: every pod on the EKS nodes can reach the DB; switch to Security Groups for Pods to isolate per app.
  allowed_security_group_ids = {
    eks_nodes = data.aws_ssm_parameter.node_security_group_id.insecure_value
  }

  # Resource Matching: topics of other apps follow the contract name "<app>-<env>-events" in this account/region.
  sns_arn_prefix          = "arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}"
  orders_events_topic_arn = "${local.sns_arn_prefix}:orders-${var.environment}-events"
}
