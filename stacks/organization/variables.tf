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

variable "accounts" {
  type = map(object({
    email               = string
    organizational_unit = string
  }))
  description = "Member accounts to create, keyed by account name (e.g. acme-prod)."

  validation {
    condition     = alltrue([for a in values(var.accounts) : contains(["Infrastructure", "Security", "Workloads"], a.organizational_unit)])
    error_message = "organizational_unit must be one of Infrastructure, Security, Workloads."
  }
}

variable "allowed_regions" {
  type        = list(string)
  description = "Regions member accounts may use; everything else is denied by the baseline SCP (global services excepted)."

  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "allowed_regions must not be empty, or every regional API call is denied."
  }
}

variable "aws_service_access_principals" {
  type        = list(string)
  description = "Service principals with trusted access to the organization (e.g. sso.amazonaws.com). Authoritative: principals enabled in AWS but not listed here are disabled on apply."

  validation {
    condition     = length(var.aws_service_access_principals) > 0
    error_message = "aws_service_access_principals must not be empty; an empty list disables trusted access for every service."
  }
}

variable "enabled_policy_types" {
  type        = list(string)
  description = "Policy types enabled in the organization root. Authoritative: types enabled in AWS but not listed here are disabled on apply (detaching their policies)."

  validation {
    condition     = contains(var.enabled_policy_types, "SERVICE_CONTROL_POLICY")
    error_message = "enabled_policy_types must include SERVICE_CONTROL_POLICY; the baseline SCP depends on it."
  }
}
