output "state_bucket_name" {
  description = "Name of the Terraform state bucket for this account (used in every stack's <env>.s3.tfbackend)."
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "ARN of the KMS key that encrypts the state bucket."
  value       = aws_kms_key.state.arn
}
