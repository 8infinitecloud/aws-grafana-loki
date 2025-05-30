################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true # disabling for example, re-evaluate for your environment
  single_nat_gateway = true

  tags = local.tags
}


module "simple_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "simple-bucket987654321"

  force_destroy = true
}