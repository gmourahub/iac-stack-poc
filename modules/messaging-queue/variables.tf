variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for the queue and DLQ. Null uses SSE-SQS. A CMK must allow sns.amazonaws.com to use it when subscribing to topics."
  default     = null
}

variable "max_receive_count" {
  type        = number
  description = "Receives before a message is moved to the DLQ."
  default     = 5

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}

variable "message_retention_seconds" {
  type        = number
  description = "Message retention on the main queue, in seconds."
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 and 1209600."
  }
}

variable "name" {
  type        = string
  description = "Full queue name, e.g. payments-staging-orders. The DLQ is named <name>-dlq."
}

variable "subscribe_topic_arns" {
  type        = map(string)
  description = "SNS topics to subscribe the queue to, keyed by a stable name (e.g. orders_events) => topic ARN."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags added to every resource."
  default     = {}
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Visibility timeout of the main queue, in seconds."
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200."
  }
}
