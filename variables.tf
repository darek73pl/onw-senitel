
variable "aws_region" {
  type = string
}

variable "name_prefix" {
  description = "Prefix for all resources of the project"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
}

variable "azs" {
  type    = list(string)
  default = []
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS nodes"
  type        = string
}

variable "container_image" {
  description = "URI of container image in ECR"
  type        = string
}



