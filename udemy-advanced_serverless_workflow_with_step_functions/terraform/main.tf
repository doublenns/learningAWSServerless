provider "aws" {
    region = "us-west-2"
    profile = "default"
}

data "archive_file" "get_expired_keys_archive" {
    type = "zip"
    source_file = "../lambda_source_code/get_expired_users.py"
    output_path = "../lambda_source_code/get_expired_users.zip"
}

resource "aws_lambda_function" "get_expired_users_lambda"{
    filename = "../lambda_source_code/get_expired_users.zip"
    function_name = "GetExpiredKeys"
    role = aws_iam_role.get_expired_users_lambda_exec_role.arn
    handler = "get_expired_users.get_expired_keys"
    timeout = 120
    source_code_hash = data.archive_file.get_expired_keys_archive.output_base64sha256
    runtime = "python3.8"
}

resource "aws_cloudwatch_log_group" "get_expired_users_lambda-log_group" {
    name = "/aws/lambda/GetExpiredKeysLambda"
    retention_in_days = 1
}

resource "aws_iam_role" "get_expired_users_lambda_exec_role" {
    name = "Lambda-GetExpiredKeys"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "123456"
        }

    ]
}
    EOF
}

resource "aws_iam_policy" "get_expired_users_lambda_policy" {
    name = "Lambda-GetExpiredKeys"
    path = "/"
    description = "IAM policy for lambda GetExpiredKeys"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:CreateLogsEvent"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:ListUsers",
                "iam:GetUser",
                "iam:ListAccessKeys"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "get_expired_users_lambda_exec_role_attachment" {
    role = aws_iam_role.get_expired_users_lambda_exec_role.name
    policy_arn = aws_iam_policy.get_expired_users_lambda_policy.arn
}
