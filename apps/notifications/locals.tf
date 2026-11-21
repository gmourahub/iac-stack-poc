locals {
  name         = "${var.service}-${var.environment}"
  cluster_name = data.aws_ssm_parameter.cluster_name.insecure_value
  account_id   = data.aws_caller_identity.current.account_id

  # Resource Matching: topics of other apps follow the contract name "<app>-<env>-events" in this account/region.
  sns_arn_prefix = "arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.region}:${local.account_id}"
  subscribed_topic_arns = {
    orders_events   = "${local.sns_arn_prefix}:orders-${var.environment}-events"
    payments_events = "${local.sns_arn_prefix}:payments-${var.environment}-events"
  }
}
