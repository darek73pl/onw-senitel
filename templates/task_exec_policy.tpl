{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "s3",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "${s3}",
                "${s3}/*"
            ]
        }
    ]
}