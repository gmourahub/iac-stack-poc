# Account-level guardrails (infra-governance: platform controls, identical in every account).
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Uses the AWS managed key alias/aws/ebs; pass a CMK with aws_ebs_default_kms_key if cross-account snapshot sharing is needed.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}
