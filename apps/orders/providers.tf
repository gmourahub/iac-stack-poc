# Credentials come from the environment (OIDC in CI, AWS_PROFILE locally).
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      owner       = var.owner
      environment = var.environment
      service     = var.service
      cost_center = var.cost_center
      managed_by  = "terraform"
    }
  }
}
