output "cluster" {
  value = {
    id   = aws_ecs_cluster.this.id
    name = aws_ecs_cluster.this.name
  }
}

output "alb" {
  value = "arn:aws:elasticloadbalancing:eu-west-1:111122223333:loadbalancer/app/mock-alb"
}