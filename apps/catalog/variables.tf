variable "cache_engine_version" {
  type        = string
  description = "Valkey engine version."
}

variable "cache_node_type" {
  type        = string
  description = "ElastiCache node type, e.g. cache.t4g.small."
}

variable "cache_num_nodes" {
  type        = number
  description = "Number of cache nodes; more than one enables automatic failover."
}

variable "cost_center" {
  type        = string
  description = "Cost center tag applied to every resource."
}

variable "db_allocated_storage" {
  type        = number
  description = "Initial storage of the database, in GiB."
}

variable "db_backup_retention_days" {
  type        = number
  description = "Days of automated database backups to keep."
}

variable "db_deletion_protection" {
  type        = bool
  description = "Blocks deleting the database instance through the API."
}

variable "db_engine_version" {
  type        = string
  description = "PostgreSQL engine version (major, or major.minor)."
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class, e.g. db.t4g.medium."
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Storage autoscaling ceiling of the database, in GiB."
}

variable "db_multi_az" {
  type        = bool
  description = "Runs the database with a standby in another availability zone."
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
