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

variable "admin_role_arn" {
  type        = string
  description = "IAM role ARN granted cluster-admin through an EKS access entry."

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.admin_role_arn))
    error_message = "admin_role_arn must be an IAM role ARN."
  }
}

variable "endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public API endpoint. Empty list = public endpoint disabled."

  validation {
    condition     = !contains(var.endpoint_public_access_cidrs, "0.0.0.0/0")
    error_message = "Opening the API endpoint to 0.0.0.0/0 is not allowed."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes minor version of the control plane (e.g. 1.34)."
}

variable "node_desired_size" {
  type        = number
  description = "Initial node count of the default managed node group (later changes are ignored by the module)."
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types of the default managed node group."
}

variable "node_max_size" {
  type        = number
  description = "Maximum node count of the default managed node group."
}

variable "node_min_size" {
  type        = number
  description = "Minimum node count of the default managed node group."
}
