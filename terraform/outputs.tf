output "eu_west_1_cluster" {
  description = "ALB and Cluster output details for EU West 1"
  value = {
    alb     = module.eu-west-1.alb
    cluster = module.eu-west-1.cluster.id
  }
}

output "us_west_2_cluster" {
  description = "ALB and Cluster output details for US West 2"
  value = {
    alb     = module.us-west-2.alb
    cluster = module.us-west-2.cluster.id
  }
}

output "ecr_repositories" {
  description = "Created ECR repository URLs"
  value       = values(aws_ecr_repository.eu-west-1)[*].repository_url
}