data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Requires the orders and payments stacks to be applied first in the same environment (deploy order).
module "events_queue" {
  source = "../../modules/messaging-queue"

  name                 = "${local.name}-inbound-events"
  subscribe_topic_arns = local.subscribed_topic_arns
}

# Bucket names are global: the account ID keeps them unique.
module "templates_bucket" {
  source = "../../modules/app-bucket"

  name = "acme-${var.environment}-${var.service}-templates-${local.account_id}"
}

module "workload_identity" {
  source = "../../modules/workload-identity"

  name            = local.name
  cluster_name    = local.cluster_name
  namespace       = var.service
  service_account = var.service

  # Queue uses SSE-SQS and the bucket SSE-S3 (kms_key_arn null), so no KMS statements are needed.
  policy_statements = {
    ConsumeEvents = {
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility",
      ]
      resources = [module.events_queue.queue_arn]
    }
    ReadWriteTemplates = {
      actions   = ["s3:GetObject", "s3:PutObject"]
      resources = ["${module.templates_bucket.bucket_arn}/templates/*"]
    }
  }
}
