variable "cost_center" {
  type        = string
  description = "Cost center tag applied to every resource."
}

variable "environment" {
  type        = string
  description = "Environment (instance) name, e.g. staging or prod. Part of every cloud resource name."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.environment))
    error_message = "environment must be lowercase alphanumeric with dashes."
  }
}

variable "owner" {
  type        = string
  description = "Owning team tag applied to every resource."
}

variable "region" {
  type        = string
  description = "AWS region for this stack instance."
}

variable "service" {
  type        = string
  description = "Service tag applied to every resource (the stack name)."
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days to keep noncurrent (previous) state versions before expiring them."
}
