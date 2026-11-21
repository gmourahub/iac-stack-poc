locals {
  # Carve the /16 per AZ index: private /20s from the bottom, public and data /24s above them.
  public_subnets  = [for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, 48 + i)]
  private_subnets = [for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i)]
  data_subnets    = [for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, 56 + i)]
}
