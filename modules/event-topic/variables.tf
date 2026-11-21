variable "fifo" {
  type        = bool
  description = "Create a FIFO topic (the .fifo suffix is appended to the name)."
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN used to encrypt the topic. Null uses the AWS managed key alias/aws/sns."
  default     = null
}

variable "name" {
  type        = string
  description = "Full topic name, e.g. orders-staging-events."
}

variable "tags" {
  type        = map(string)
  description = "Tags added to every resource."
  default     = {}
}
