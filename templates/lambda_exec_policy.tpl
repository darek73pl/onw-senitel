{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudWatch",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Sid": "dynamodb",
            "Effect": "Allow",
            "Action": "dynamodb:*",
            "Resource": "${dynamodb}"
        },
        {
            "Sid": "s3",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "${s3}",
                "${s3}/*"
            ]
        },
        {
            "Sid": "ECS",
            "Effect": "Allow",
            "Action": [
                "ecs:PutAttributes",
                "ecs:ListAttributes",
                "ecs:ExecuteCommand",
                "ecs:StartTask",
                "ecs:DescribeTaskSets",
                "ecs:DeleteTaskSet",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeClusters",
                "ecs:ListServices",
                "ecs:ListAccountSettings",
                "ecs:DescribeCapacityProviders",
                "ecs:ListTagsForResource",
                "ecs:RunTask",
                "ecs:ListTasks",
                "ecs:ListTaskDefinitionFamilies",
                "ecs:StopTask",
                "ecs:DescribeServices",
                "ecs:ListContainerInstances",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeTasks",
                "ecs:ListTaskDefinitions",
                "ecs:UpdateTaskSet",
                "ecs:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Action": "iam:PassRole",
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": "ecs-tasks.amazonaws.com"
                }
            }
        },
        {
            "Action": "iam:PassRole",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::*:role/ecsInstanceRole*"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": [
                        "ec2.amazonaws.com",
                        "ec2.amazonaws.com.cn"
                    ]
                }
            }
        },
        {
            "Action": "iam:PassRole",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::*:role/ecsAutoscaleRole*"
            ],
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": [
                        "application-autoscaling.amazonaws.com",
                        "application-autoscaling.amazonaws.com.cn"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ecs.amazonaws.com",
                        "ecs.application-autoscaling.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com"
                    ]
                }
            }
        }
    ]
}