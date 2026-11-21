variable "cost_center" {
  type        = string
  description = "Cost center tag applied to every resource."
}

variable "environment" {
  type        = string
  description = "Environment name (staging, prod). Part of every resource name and of the registry paths."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.environment))
    error_message = "environment must be lowercase alphanumeric with dashes, 2-16 characters."
  }
}

variable "owner" {
  type        = string
  description = "Owning team, applied as the owner tag."
}

variable "region" {
  type        = string
  description = "AWS region of the environment."
}

variable "service" {
  type        = string
  description = "Application name. Used in resource names and as the Kubernetes namespace and service account."
}
