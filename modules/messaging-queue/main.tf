locals {
  # SSE-SQS when no CMK is given; null (not false) when a CMK is set, the two arguments conflict.
  sqs_managed_sse = var.kms_key_arn == null ? true : null
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  message_retention_seconds = 1209600 # 14 days, the SQS maximum: time to inspect failed messages
  sqs_managed_sse_enabled   = local.sqs_managed_sse
  kms_master_key_id         = var.kms_key_arn
  tags                      = var.tags
}

resource "aws_sqs_queue" "this" {
  name                       = var.name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  sqs_managed_sse_enabled    = local.sqs_managed_sse
  kms_master_key_id          = var.kms_key_arn
  tags                       = var.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscribe_topic_arns

  topic_arn = each.value
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn
}

# Only the subscribed topics may send to the queue.
resource "aws_sqs_queue_policy" "this" {
  count = length(var.subscribe_topic_arns) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSubscribedTopics"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.this.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = values(var.subscribe_topic_arns) }
      }
    }]
  })
}
