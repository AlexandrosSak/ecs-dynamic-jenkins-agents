variable "name_prefix" { type = string }
variable "cluster_instance_type" { type = string }
variable "iam_instance_profile" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "size_max" { type = number }
variable "size_desired" { type = number }
variable "volume_size" { type = number }
variable "allowed_cidr_blocks" { type = list(string) }
variable "log_retention_days" { type = number, default = 14 }
variable "tags" { type = map(string), default = {} }