terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


data "aws_availability_zones" "available" {}

module "sntl-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = length(var.azs) == 0 ? data.aws_availability_zones.available.names : var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

}

resource "aws_vpc_endpoint" "sntl-s3-endpoint-gateway" {
  vpc_id            = module.sntl-vpc.vpc_id
  service_name      = "com.amazonaws.eu-central-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.sntl-vpc.private_route_table_ids

  tags = {
    Name = "${var.name_prefix}-s3-endpoint"
  }
}

# dynamodb

resource "aws_dynamodb_table" "sntl-dynamodb-table" {
  name           = "${var.name_prefix}-dynamodb"
  billing_mode   = "PROVISIONED"
  hash_key       = "cam_id"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "cam_id"
    type = "S"
  }
}

# s3

resource "aws_s3_bucket" "sntl-s3" {
  bucket = "${var.name_prefix}-metadata-store"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "sntl-s3" {
  bucket = aws_s3_bucket.sntl-s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# lambda

resource "aws_iam_role" "sntl-lambda-exec-role" {
  name = "${var.name_prefix}-lambda-exec-role"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17"
      Statement : [
        {
          Action : "sts:AssumeRole"
          Effect : "Allow"
          Sid : ""
          Principal : {
            Service : "lambda.amazonaws.com"
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "sntl-lambda-exec-policy" {
  name = "${var.name_prefix}-lambda-exec-policy"
  role = aws_iam_role.sntl-lambda-exec-role.id

  policy = templatefile("${path.module}/templates/lambda_exec_policy.tpl", {
    dynamodb = aws_dynamodb_table.sntl-dynamodb-table.arn
    s3       = aws_s3_bucket.sntl-s3.arn
  })
}

data "archive_file" "sntl-start" {
  type             = "zip"
  output_file_mode = "0666"
  source_file      = "${path.module}/code/lambda_sentinel_start.py"
  output_path      = "${path.module}/code/output/lambda_sentinel_start.zip"
}

data "archive_file" "sntl-stop" {
  type             = "zip"
  output_file_mode = "0666"
  source_file      = "${path.module}/code/lambda_sentinel_stop.py"
  output_path      = "${path.module}/code/output/lambda_sentinel_stop.zip"
}

resource "aws_lambda_function" "sntl-lambda-start" {
  filename      = "${path.module}/code/output/lambda_sentinel_start.zip"
  function_name = "${var.name_prefix}-lambda-start-sentinel"
  role          = aws_iam_role.sntl-lambda-exec-role.arn
  handler       = "lambda_sentinel_start.lambda_handler"
  timeout       = 60

  source_code_hash = data.archive_file.sntl-start.output_base64sha256 

  runtime = "python3.8"

  environment {
    variables = {
      DYNAMO_DB             = aws_dynamodb_table.sntl-dynamodb-table.name
      S3_BUCKET             = aws_s3_bucket.sntl-s3.id
      ECS_CLUSTER           = module.stnl-ecs-cluster.name
      ECS_TASK              = "${var.name_prefix}-ecs-td"
      ECS_CONTAINER         = "${var.name_prefix}-container"
      ECS_CAPACITY_PROVIDER = "${var.name_prefix}-ecs-cp"
    }
  }
}

resource "aws_lambda_function" "sntl-lambda-stop" {
  filename      = "${path.module}/code/output/lambda_sentinel_stop.zip"
  function_name = "${var.name_prefix}-lambda-stop-sentinel"
  role          = aws_iam_role.sntl-lambda-exec-role.arn
  handler       = "lambda_sentinel_stop.lambda_handler"
  timeout       = 60

  source_code_hash = data.archive_file.sntl-stop.output_base64sha256 

  runtime = "python3.8"

  environment {
    variables = {
      DYNAMO_DB             = aws_dynamodb_table.sntl-dynamodb-table.name
      ECS_CLUSTER           = module.stnl-ecs-cluster.name
    }
  }
}

# ECS

data "aws_ssm_parameter" "sntl-ecs-ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_iam_policy" "sntl-ecs-exec-policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "sntl-ecs-exec-role" {
  name = "${var.name_prefix}-ecs-exec-role"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17"
      Statement : [
        {
          Action : "sts:AssumeRole"
          Effect : "Allow"
          Sid : ""
          Principal : {
            Service : "ecs-tasks.amazonaws.com"
          }
        }
      ]
    }
  )

  managed_policy_arns = [data.aws_iam_policy.sntl-ecs-exec-policy.arn]
}

resource "aws_iam_role" "sntl-ecs-task-exec-role" {
  name = "${var.name_prefix}-ecs-task-exec-role"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17"
      Statement : [
        {
          Action : "sts:AssumeRole"
          Effect : "Allow"
          Sid : ""
          Principal : {
            Service : "ecs-tasks.amazonaws.com"
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "sntl-ecs-task-exec-policy" {
  name = "${var.name_prefix}-ecs-task-exec-policy"
  role = aws_iam_role.sntl-ecs-task-exec-role.id

  policy = templatefile("${path.module}/templates/task_exec_policy.tpl", {
    s3 = aws_s3_bucket.sntl-s3.arn
  })
}

resource "aws_security_group" "sntl-sg-ecs-asg" {
  name        = "${var.name_prefix}-sg-ecs-asg"
  description = "Security group for EC2 instance for ECS cluster"
  vpc_id      = module.sntl-vpc.vpc_id

  ingress {
    description = "Access to node by SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.sntl-vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg-ecs-asg"
  }
}

module "stnl-iam-instance-profile" {
  source      = "./modules/ecs-instance-profile"
  name        = "${var.name_prefix}-instance-profile"
  ssm_enabled = true
}

resource "aws_launch_template" "stnl-asg-lt" {
  name                    = "${var.name_prefix}-ecs-lt"
  image_id                = data.aws_ssm_parameter.sntl-ecs-ami.value
  instance_type           = var.ecs_instance_type
  disable_api_termination = true

  iam_instance_profile {
    name = module.stnl-iam-instance-profile.iam_instance_profile_id
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sntl-sg-ecs-asg.id]
  }

  user_data = base64encode(templatefile("${path.module}/templates/ec2_userdata.tpl", {
    ecs_cluster = module.stnl-ecs-cluster.name
  }))
}

resource "aws_autoscaling_group" "stnl-asg" {
  name                  = "${var.name_prefix}-ecs-asg"
  max_size              = 10
  min_size              = 1
  desired_capacity      = 2
  health_check_type     = "EC2"
  vpc_zone_identifier   = module.sntl-vpc.private_subnets
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.stnl-asg-lt.id
    version = aws_launch_template.stnl-asg-lt.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ecs-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "stnl-ecs-cp" {
  name = "${var.name_prefix}-ecs-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.stnl-asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {

      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

module "stnl-ecs-cluster" {
  source = "./modules/ecs-cluster"

  name               = "${var.name_prefix}-ecs"
  capacity_providers = [aws_ecs_capacity_provider.stnl-ecs-cp.name]

  default_capacity_provider_strategy = [
    {
      "capacity_provider" : "${var.name_prefix}-ecs-cp"
      "weight" : 1
      "base" : 0
    }
  ]
}

resource "aws_ecs_task_definition" "stnl-ecs-td" {
  family             = "${var.name_prefix}-ecs-td"
  execution_role_arn = aws_iam_role.sntl-ecs-exec-role.arn
  task_role_arn      = aws_iam_role.sntl-ecs-task-exec-role.arn

  container_definitions = templatefile("${path.module}/templates/container_definition.tpl", {
    name   = "${var.name_prefix}-container"
    image  = var.container_image
    cpu    = 128    
    memory = 128
  })
}