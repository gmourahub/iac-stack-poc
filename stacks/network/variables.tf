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

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the subnets (one public, private and data subnet each)."

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "This network is designed for exactly 3 availability zones."
  }
}

variable "flow_log_retention_days" {
  type        = number
  description = "Retention of VPC flow logs in CloudWatch Logs, in days."
}

variable "single_nat_gateway" {
  type        = bool
  description = "true = one shared NAT gateway (cheaper, single-AZ egress); false = one NAT gateway per AZ."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block. Must be a /16 (subnets are carved from it)."

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid /16 CIDR."
  }
}
