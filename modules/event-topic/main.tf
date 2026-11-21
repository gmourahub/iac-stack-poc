resource "aws_sns_topic" "this" {
  # SNS requires the ".fifo" suffix on FIFO topics.
  name                        = var.fifo ? "${var.name}.fifo" : var.name
  fifo_topic                  = var.fifo
  content_based_deduplication = var.fifo
  kms_master_key_id           = coalesce(var.kms_key_arn, "alias/aws/sns")
  tags                        = var.tags
}
