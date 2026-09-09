data "aws_caller_identity" "current" {}

# EC2 Instance Assume Role Policy
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "ecs-instances"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = merge(var.tags, {
    Adzuna-Service = "internal"
    Name           = "ecs-instances"
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "ecs-instances"
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Adzuna-Service = "internal"
    Name           = "ecs-instances"
  })
}

# Detailed IAM Permissions Policy Document for EC2 Capacity
data "aws_iam_policy_document" "ecs-instances" {
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  statement {
    actions   = ["ecs:Describe*", "ecs:List*"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:RunTask",
      "ecs:StopTask",
    ]
    resources = [
      module.eu-west-1.cluster_id,
      module.us-west-2.cluster_id,
      "arn:aws:ecs:eu-west-1:${data.aws_caller_identity.current.account_id}:task-definition/*",
      "arn:aws:ecs:us-west-2:${data.aws_caller_identity.current.account_id}:task-definition/*",
      "arn:aws:ecs:eu-west-1:${data.aws_caller_identity.current.account_id}:task/*",
      "arn:aws:ecs:us-west-2:${data.aws_caller_identity.current.account_id}:task/*",
      "arn:aws:ecs:eu-west-1:${data.aws_caller_identity.current.account_id}:container-instance/*",
      "arn:aws:ecs:us-west-2:${data.aws_caller_identity.current.account_id}:container-instance/*",
      "arn:aws:ecs:eu-west-1:${data.aws_caller_identity.current.account_id}:service/*",
      "arn:aws:ecs:us-west-2:${data.aws_caller_identity.current.account_id}:service/*",
    ]
  }

  statement {
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  statement {
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-execution-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-task-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::adzuna-infra-artifacts-*",
      "arn:aws:s3:::adzuna-infra-artifacts-*/*"
    ]
  }
}

resource "aws_iam_policy" "ecs-instances" {
  name   = "ecs-instances"
  policy = data.aws_iam_policy_document.ecs-instances.json

  tags = merge(var.tags, {
    Adzuna-Service = "internal"
    Name           = "ecs-instances"
  })
}

locals {
  this_policy_attachments = {
    ecs-instances        = aws_iam_policy.ecs-instances.arn
    ecs2                 = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    ssm_managed_instance = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_iam_role_policy_attachment" "this_policy_attachments" {
  for_each   = local.this_policy_attachments
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Global ECS Task Execution Role
data "aws_iam_policy_document" "assume_ecs_tasks" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_tasks.json

  tags = merge(var.tags, {
    Adzuna-Service = "internal"
    Name           = "ecsTaskExecutionRole"
  })
}

locals {
  ecsTaskExecutionRole_policies = {
    ecs = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole" {
  for_each   = local.ecsTaskExecutionRole_policies
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = each.value
}