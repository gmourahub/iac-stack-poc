variable "allocated_storage" {
  type        = number
  description = "Initial storage in GiB."
}

variable "allowed_security_group_ids" {
  type        = map(string)
  description = "Security groups allowed to connect on 5432, keyed by a stable name (e.g. eks_nodes) => SG ID."
}

variable "backup_retention_days" {
  type        = number
  description = "Days to keep automated backups."

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35 (0 would disable backups)."
  }
}

variable "database_name" {
  type        = string
  description = "Name of the initial database."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must start with a letter and use only letters, digits and underscores (max 63)."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Block deletion of the instance."
  default     = true
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version, e.g. 17.4."
}

variable "instance_class" {
  type        = string
  description = "RDS instance class, e.g. db.t4g.medium."
}

variable "max_allocated_storage" {
  type        = number
  description = "Storage autoscaling ceiling in GiB."
}

variable "multi_az" {
  type        = bool
  description = "Run a standby in another AZ."
}

variable "name" {
  type        = string
  description = "Full instance identifier, e.g. orders-staging."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private (data) subnets for the DB subnet group."
}

variable "tags" {
  type        = map(string)
  description = "Tags added to every resource."
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC of the database security group."
}
