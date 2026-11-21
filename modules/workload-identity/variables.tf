variable "cluster_name" {
  type        = string
  description = "EKS cluster that runs the workload."
}

variable "name" {
  type        = string
  description = "Full IAM role name, e.g. orders-staging-app."
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the service account."
}

variable "policy_statements" {
  type = map(object({
    actions   = list(string)
    resources = list(string)
  }))
  description = "Allow statements of the inline policy, keyed by Sid. Use specific actions and resource ARNs."

  validation {
    condition     = length(var.policy_statements) > 0
    error_message = "policy_statements needs at least one statement."
  }

  validation {
    condition     = alltrue([for sid in keys(var.policy_statements) : can(regex("^[A-Za-z0-9]+$", sid))])
    error_message = "policy_statements keys are IAM Sids: letters and digits only."
  }

  validation {
    condition     = alltrue([for s in values(var.policy_statements) : !contains(s.actions, "*") && !contains(s.resources, "*")])
    error_message = "Wildcard \"*\" actions or resources are not allowed: grant least privilege."
  }
}

variable "service_account" {
  type        = string
  description = "Kubernetes service account bound to the role."
}

variable "tags" {
  type        = map(string)
  description = "Tags added to every resource."
  default     = {}
}
