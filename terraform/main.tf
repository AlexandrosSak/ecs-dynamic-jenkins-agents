terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"
}

provider "aws" {
  region = "us-west-2"
  alias  = "us-west-2"
}

module "eu-west-1" {
  providers = { aws = aws.eu-west-1 }
  source    = "./modules/ecs_cluster"

  certificate_arn       = local.acm.eu_west_1.arn
  cluster_instance_type = "c5.2xlarge"
  cluster_name          = var.profile
  iam_instance_profile  = aws_iam_instance_profile.this.name
  private_subnets       = local.vpc.eu-west-1.private_subnets
  public_subnets        = local.vpc.eu-west-1.public_subnets
  size_max              = 5
  size_desired          = 5
  volume_size           = 100
  vpc_id                = local.vpc.eu-west-1.vpc_id
  allowed_cidr_blocks   = [local.vpc.eu-west-1.vpc_cidr]
  name_prefix           = "jenkins-agents-eu"

  tags = merge(var.tags, {
    Service = "internal"
  })
}

module "us-west-2" {
  providers = { aws = aws.us-west-2 }
  source    = "./modules/ecs_cluster"

  certificate_arn       = local.acm.us_west_2.arn
  cluster_instance_type = "c5.2xlarge"
  cluster_name          = "${var.profile}-us"
  iam_instance_profile  = aws_iam_instance_profile.this.name
  private_subnets       = local.vpc.us-west-2.private_subnets
  public_subnets        = local.vpc.us-west-2.public_subnets
  size_max              = 5
  size_desired          = 5
  volume_size           = 100
  vpc_id                = local.vpc.us-west-2.vpc_id
  allowed_cidr_blocks   = [local.vpc.us-west-2.vpc_cidr]
  name_prefix           = "jenkins-agents-us"

  tags = merge(var.tags, {
    Service = "internal"
  })
}