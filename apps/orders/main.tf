data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

module "database" {
  source = "../../modules/app-database"

  name                       = local.name
  vpc_id                     = local.vpc_id
  subnet_ids                 = local.data_subnet_ids
  allowed_security_group_ids = local.allowed_security_group_ids
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  max_allocated_storage      = var.db_max_allocated_storage
  multi_az                   = var.db_multi_az
  backup_retention_days      = var.db_backup_retention_days
  deletion_protection        = var.db_deletion_protection
  database_name              = var.service
}

module "cache" {
  source = "../../modules/app-cache"

  name                       = local.name
  vpc_id                     = local.vpc_id
  subnet_ids                 = local.data_subnet_ids
  allowed_security_group_ids = local.allowed_security_group_ids
  engine_version             = var.cache_engine_version
  node_type                  = var.cache_node_type
  num_cache_clusters         = var.cache_num_nodes
}

# Public contract: other apps build this ARN from the name "<app>-<env>-events" (see README).
module "events_topic" {
  source = "../../modules/event-topic"

  name = "${local.name}-events"
}

module "commands_queue" {
  source = "../../modules/messaging-queue"

  name = "${local.name}-commands"
}

module "workload_identity" {
  source = "../../modules/workload-identity"

  name            = local.name
  cluster_name    = local.cluster_name
  namespace       = var.service
  service_account = var.service

  # Topic and queue use AWS managed keys or SSE-SQS, so no KMS statements are needed.
  policy_statements = {
    PublishEvents = {
      actions   = ["sns:Publish"]
      resources = [module.events_topic.topic_arn]
    }
    ConsumeCommands = {
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility",
      ]
      resources = [module.commands_queue.queue_arn]
    }
    # IAM database auth as DB user var.service (created once outside Terraform, see README); no master secret.
    ConnectDatabase = {
      actions   = ["rds-db:connect"]
      resources = ["arn:${data.aws_partition.current.partition}:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.database.db_resource_id}/${var.service}"]
    }
  }
}
