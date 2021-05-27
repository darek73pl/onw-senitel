
aws_region = "eu-central-1"

name_prefix = "ec1-stnl"

vpc_cidr = "10.0.0.0/16"

public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

ecs_instance_type = "t2.micro"

container_image = "502797923568.dkr.ecr.eu-central-1.amazonaws.com/sentinel"


