mock_provider "aws" {
  override_during = plan

  mock_resource "aws_security_group" {
    defaults = {
      id = "sg-0db0000000000000a"
    }
  }

  mock_resource "aws_db_instance" {
    defaults = {
      resource_id = "db-ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      master_user_secret = [{
        kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
        secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds-db-mock-AbCdEf"
        secret_status = "active"
      }]
    }
  }
}

variables {
  name                       = "orders-staging"
  vpc_id                     = "vpc-0123456789abcdef0"
  subnet_ids                 = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  allowed_security_group_ids = { eks_nodes = "sg-0eks000000000000a" }
  engine_version             = "17.4"
  instance_class             = "db.t4g.medium"
  allocated_storage          = 20
  max_allocated_storage      = 100
  multi_az                   = false
  backup_retention_days      = 7
  database_name              = "orders"
}

run "private_encrypted_and_protected" {
  command = plan

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "Database must not be publicly accessible."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted
    error_message = "Storage must be encrypted."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password && aws_db_instance.this.password == null
    error_message = "Master password must be managed by RDS in Secrets Manager."
  }

  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled
    error_message = "IAM database authentication must always be enabled (apps use rds-db:connect, not the master secret)."
  }

  assert {
    condition     = output.db_resource_id == "db-ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    error_message = "Output must expose the instance resource ID for rds-db:connect ARNs."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection && !aws_db_instance.this.skip_final_snapshot
    error_message = "Deletion protection and a final snapshot must be on by default."
  }

  assert {
    condition     = aws_db_instance.this.performance_insights_enabled
    error_message = "Performance Insights must be enabled."
  }

  assert {
    condition     = output.master_user_secret_arn == "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds-db-mock-AbCdEf"
    error_message = "Output must expose the managed secret ARN."
  }
}

run "ingress_only_from_allowed_security_groups" {
  command = plan

  variables {
    allowed_security_group_ids = {
      eks_nodes = "sg-0eks000000000000a"
      bastion   = "sg-0bas000000000000a"
    }
  }

  assert {
    condition     = toset(keys(aws_vpc_security_group_ingress_rule.postgres)) == toset(["eks_nodes", "bastion"])
    error_message = "One ingress rule per allowed security group key."
  }

  assert {
    condition = alltrue([for r in aws_vpc_security_group_ingress_rule.postgres :
    r.from_port == 5432 && r.to_port == 5432 && r.cidr_ipv4 == null && r.referenced_security_group_id != null])
    error_message = "Ingress must be 5432 from security groups only, never from CIDRs."
  }
}

run "rejects_zero_backup_retention" {
  command = plan

  variables {
    backup_retention_days = 0
  }

  expect_failures = [var.backup_retention_days]
}
