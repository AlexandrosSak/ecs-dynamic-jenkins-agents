variable "profile" {
  type        = string
  description = "Environment profile name"
  default     = "jenkins-agents"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Project     = "Jenkins-Infrastructure"
  }
}

locals {
  acm = {
    eu_west_1 = {
      arn = "arn:aws:acm:eu-west-1:111122223333:certificate/dummy-cert-id-eu"
    }
    us_west_2 = {
      arn = "arn:aws:acm:us-west-2:111122223333:certificate/dummy-cert-id-us"
    }
  }

  vpc = {
    eu-west-1 = {
      vpc_id          = "vpc-01234567eu"
      vpc_cidr        = "10.0.0.0/16"
      private_subnets = ["subnet-01eu1", "subnet-01eu2"]
      public_subnets  = ["subnet-02eu1", "subnet-02eu2"]
    }
    us-west-2 = {
      vpc_id          = "vpc-01234567us"
      vpc_cidr        = "10.1.0.0/16"
      private_subnets = ["subnet-01us1", "subnet-01us2"]
      public_subnets  = ["subnet-02us1", "subnet-02us2"]
    }
  }
}