variable "force_destroy" {
  type        = bool
  description = "Allow destroying the bucket with objects in it. Keep false for real data."
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for SSE-KMS. Null uses SSE-S3 (AES256)."
  default     = null
}

variable "name" {
  type        = string
  description = "Full, globally unique bucket name, e.g. acme-staging-notifications-templates."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be a valid S3 bucket name (3-63 chars, lowercase letters, digits, dots and hyphens)."
  }
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days before noncurrent object versions are deleted."
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days must be at least 1."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags added to every resource."
  default     = {}
}
