# Partial configuration: terraform init -backend-config=environments/<env>.s3.tfbackend
terraform {
  backend "s3" {}
}
