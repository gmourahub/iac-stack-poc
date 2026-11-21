module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.30"

  name                = "acme-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  authentication_mode = "API"
  deletion_protection = true

  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  subnet_ids               = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  control_plane_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  # Private API endpoint always; the public one only exists when CIDRs are allow-listed in tfvars.
  endpoint_private_access      = true
  endpoint_public_access       = length(var.endpoint_public_access_cidrs) > 0
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # Envelope encryption of Kubernetes secrets with a module-created KMS key.
  encryption_config = {
    resources = ["secrets"]
  }

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  access_entries = {
    platform_admin = {
      principal_arn = var.admin_role_arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }
}
