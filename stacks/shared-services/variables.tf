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

variable "deploy_targets" {
  type        = map(string)
  description = "Deploy targets: key = target environment (staging, prod), value = GitHub environment name allowed to assume its role."
}

variable "ecr_repositories" {
  type        = set(string)
  description = "Application names that get an ECR repository (acme-<env>/<app>)."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository (owner/name) whose workflows may assume the deploy roles."

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form."
  }
}

variable "max_image_count" {
  type        = number
  description = "Images kept per repository; older ones are expired."
}

variable "organization_id" {
  type        = string
  description = "AWS Organizations ID (o-...) used in aws:PrincipalOrgID / aws:ResourceOrgID conditions."

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "organization_id must look like o-xxxxxxxxxx."
  }
}

variable "untagged_image_expiration_days" {
  type        = number
  description = "Days before untagged images are expired."
}
