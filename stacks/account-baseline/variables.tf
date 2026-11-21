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

variable "deploy_role_max_session_duration" {
  type        = number
  description = "Max session duration of the deploy role, in seconds. Role chaining caps sessions at 1 hour anyway."
  default     = 3600
}

variable "shared_account_id" {
  type        = string
  description = "Account ID of acme-shared, where the CI deploy roles acme-shared-deploy-<env> live (stacks/shared-services)."

  validation {
    condition     = can(regex("^[0-9]{12}$", var.shared_account_id))
    error_message = "shared_account_id must be a 12-digit AWS account ID."
  }
}
