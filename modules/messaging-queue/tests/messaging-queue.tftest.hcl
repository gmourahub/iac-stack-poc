mock_provider "aws" {
  override_during = plan

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
      id  = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
      url = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
    }
  }
}

variables {
  name = "payments-staging-orders"
}

run "queue_with_dlq_and_no_subscriptions" {
  command = plan

  assert {
    condition     = aws_sqs_queue.dlq.name == "payments-staging-orders-dlq"
    error_message = "DLQ must be named <name>-dlq."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue.this.redrive_policy).deadLetterTargetArn == aws_sqs_queue.dlq.arn
    error_message = "Main queue must redrive to the DLQ."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue.this.redrive_policy).maxReceiveCount == 5
    error_message = "Default maxReceiveCount must be 5."
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled && aws_sqs_queue.dlq.sqs_managed_sse_enabled
    error_message = "Both queues must use SSE-SQS when no KMS key is given."
  }

  assert {
    condition     = length(aws_sns_topic_subscription.this) == 0 && length(aws_sqs_queue_policy.this) == 0
    error_message = "No subscription or queue policy without topics."
  }
}

run "subscribes_to_each_topic_and_restricts_senders" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
    subscribe_topic_arns = {
      orders_events   = "arn:aws:sns:us-east-1:123456789012:orders-staging-events"
      payments_events = "arn:aws:sns:us-east-1:123456789012:payments-staging-events"
    }
  }

  assert {
    condition     = toset(keys(aws_sns_topic_subscription.this)) == toset(["orders_events", "payments_events"])
    error_message = "One subscription per topic key."
  }

  assert {
    condition     = aws_sns_topic_subscription.this["orders_events"].topic_arn == "arn:aws:sns:us-east-1:123456789012:orders-staging-events" && aws_sns_topic_subscription.this["orders_events"].protocol == "sqs"
    error_message = "Subscription must point the topic to the queue over sqs."
  }

  assert {
    condition = toset(jsondecode(aws_sqs_queue_policy.this[0].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"]) == toset([
      "arn:aws:sns:us-east-1:123456789012:orders-staging-events",
      "arn:aws:sns:us-east-1:123456789012:payments-staging-events",
    ])
    error_message = "Queue policy must allow only the subscribed topics."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue_policy.this[0].policy).Statement[0].Action == "sqs:SendMessage"
    error_message = "Queue policy must grant only sqs:SendMessage."
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == var.kms_key_arn
    error_message = "Queue must use the given KMS key instead of SSE-SQS."
  }
}

run "rejects_invalid_max_receive_count" {
  command = plan

  variables {
    max_receive_count = 0
  }

  expect_failures = [var.max_receive_count]
}
