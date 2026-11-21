variable "allowed_security_group_ids" {
  type        = map(string)
  description = "Security groups allowed to connect on 6379, keyed by a stable name (e.g. eks_nodes) => SG ID."
}

variable "engine" {
  type        = string
  description = "Cache engine: valkey or redis."
  default     = "valkey"

  validation {
    condition     = contains(["valkey", "redis"], var.engine)
    error_message = "engine must be valkey or redis."
  }
}

variable "engine_version" {
  type        = string
  description = "Engine version, e.g. 8.0 for valkey."
}

variable "name" {
  type        = string
  description = "Full replication group ID, e.g. orders-staging (lowercase, max 40 characters)."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,39}$", var.name))
    error_message = "name must start with a letter and use lowercase letters, digits and hyphens (max 40)."
  }
}

variable "node_type" {
  type        = string
  description = "Node type, e.g. cache.t4g.small."
}

variable "num_cache_clusters" {
  type        = number
  description = "Number of nodes (primary + replicas). More than 1 enables automatic failover and Multi-AZ."

  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "num_cache_clusters must be between 1 and 6."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private (data) subnets for the cache subnet group."
}

variable "tags" {
  type        = map(string)
  description = "Tags added to every resource."
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC of the cache security group."
}
