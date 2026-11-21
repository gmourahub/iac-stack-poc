# Partial configuration: terraform init -backend-config=environments/<env>.s3.tfbackend
# Chicken-and-egg: this stack creates that bucket, so the first apply in each account runs on local state
# (temporary backend_override.tf, gitignored) and is then migrated here. See README.md.
terraform {
  backend "s3" {}
}
