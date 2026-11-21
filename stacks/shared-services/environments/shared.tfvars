region      = "us-east-1"
environment = "shared"
service     = "shared-services"
owner       = "platform-team"
cost_center = "platform"

# Output organization_id of stacks/organization. Example value.
organization_id = "o-exampleorg1"

ecr_repositories               = ["orders", "payments", "notifications", "catalog"]
max_image_count                = 200
untagged_image_expiration_days = 7

github_repository = "acme/platform"
deploy_targets = {
  staging = "staging"
  prod    = "production"
}
