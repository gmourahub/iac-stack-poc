# Integration Registry (ARCHITECTURE.md): the only platform value this app needs is the cluster.
# insecure_value: a plain String; `value` is always marked sensitive.
data "aws_ssm_parameter" "cluster_name" {
  name = "/platform/${var.environment}/eks/cluster_name"
}
