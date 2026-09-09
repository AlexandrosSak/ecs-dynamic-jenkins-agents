locals {
  ecr_repositories_eu = [
    "jenkins-agents",
    "adminerevo",
    "vector-embeddings-api"
  ]
}

resource "aws_ecr_repository" "eu-west-1" {
  provider             = aws.eu-west-1
  for_each             = toset(local.ecr_repositories_eu)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_registry_policy" "eu-west-1" {
  provider = aws.eu-west-1
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccountRegistryPolicy"
        Effect = "Allow"
        Principal = {
          "AWS" : data.aws_caller_identity.current.account_id
        }
        Action = [
          "ecr:ReplicateImage"
        ]
        Resource = [
          "arn:aws:ecr:eu-west-1:${data.aws_caller_identity.current.account_id}:repository/*"
        ]
      }
    ]
  })
}