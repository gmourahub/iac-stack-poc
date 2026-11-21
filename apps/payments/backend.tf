# Partial configuration: environments/<env>.s3.tfbackend supplies bucket, key and region.
terraform {
  backend "s3" {}
}
