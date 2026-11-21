mock_provider "aws" {}

variables {
  name = "orders-staging-events"
}

run "standard_topic_uses_aws_managed_key" {
  command = plan

  assert {
    condition     = aws_sns_topic.this.name == "orders-staging-events"
    error_message = "Standard topic must keep the given name."
  }

  assert {
    condition     = aws_sns_topic.this.kms_master_key_id == "alias/aws/sns"
    error_message = "Topic must fall back to alias/aws/sns when no key is given."
  }

  assert {
    condition     = aws_sns_topic.this.fifo_topic == false
    error_message = "Topic must be standard by default."
  }
}

run "fifo_topic_with_cmk" {
  command = plan

  variables {
    fifo        = true
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = aws_sns_topic.this.name == "orders-staging-events.fifo" && aws_sns_topic.this.fifo_topic
    error_message = "FIFO topic must have the .fifo suffix."
  }

  assert {
    condition     = aws_sns_topic.this.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
    error_message = "Topic must use the given KMS key."
  }
}
