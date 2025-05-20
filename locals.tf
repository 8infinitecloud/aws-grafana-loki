locals {
  region      = "us-east-1"
  name        = "amg-ex-${replace(basename(path.cwd), "_", "-")}"
  description = "AWS Managed Grafana service for ${local.name}"

# VPC
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

# ECS
  container_name = "ecsdemo-frontend"
  container_port = 3000

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-manage-service-grafana"
    GithubOrg  = "terraform-aws-modules"
  }
}