mock_provider "aws" {
  override_during = plan

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/orders-staging-app"
    }
  }
}

variables {
  name            = "orders-staging-app"
  cluster_name    = "acme-staging"
  namespace       = "orders"
  service_account = "orders"
  policy_statements = {
    PublishOrderEvents = {
      actions   = ["sns:Publish"]
      resources = ["arn:aws:sns:us-east-1:123456789012:orders-staging-events"]
    }
    ConsumeCommands = {
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
      resources = ["arn:aws:sqs:us-east-1:123456789012:orders-staging-commands"]
    }
  }
}

run "trust_policy_allows_only_eks_pod_identity" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Principal == { Service = "pods.eks.amazonaws.com" }
    error_message = "Trust policy must allow only pods.eks.amazonaws.com."
  }

  assert {
    condition     = toset(jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Action) == toset(["sts:AssumeRole", "sts:TagSession"])
    error_message = "Pod Identity needs sts:AssumeRole and sts:TagSession."
  }
}

run "inline_policy_built_from_statements" {
  command = plan

  assert {
    condition     = toset([for s in jsondecode(aws_iam_role_policy.this.policy).Statement : s.Sid]) == toset(["PublishOrderEvents", "ConsumeCommands"])
    error_message = "One policy statement per map key, with the key as Sid."
  }

  assert {
    condition     = alltrue([for s in jsondecode(aws_iam_role_policy.this.policy).Statement : s.Effect == "Allow"])
    error_message = "Statements must be Allow."
  }
}

run "association_binds_service_account_to_role" {
  command = plan

  assert {
    condition = (
      aws_eks_pod_identity_association.this.cluster_name == "acme-staging" &&
      aws_eks_pod_identity_association.this.namespace == "orders" &&
      aws_eks_pod_identity_association.this.service_account == "orders" &&
      aws_eks_pod_identity_association.this.role_arn == "arn:aws:iam::123456789012:role/orders-staging-app"
    )
    error_message = "Association must bind the namespace/service account to the role."
  }
}

run "rejects_wildcards" {
  command = plan

  variables {
    policy_statements = {
      Everything = {
        actions   = ["*"]
        resources = ["*"]
      }
    }
  }

  expect_failures = [var.policy_statements]
}
