provider "aws" {
    region = "us-west-2"
    profile = "default"
}


## Lambda deployment
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
    name = "/aws/lambda/GetExpiredKeys"
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
                "logs:PutLogEvents"
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


## Step Function deployment
resource "aws_iam_role" "get_expired_users_sfn_exec_role" {
    name = "SFN-GetExpiredKeys"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "states.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "123456"
        }

    ]
}
    EOF
}

resource "aws_iam_policy" "get_expired_users_sfn_policy" {
    name = "SFN-GetExpiredKeys"
    path = "/"
    description = "IAM policy for step function GetExpiredKeys"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "${aws_lambda_function.get_expired_users_lambda.arn}",
            "Effect": "Allow"
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "get_expired_users_sfn_exec_role_attachment" {
    role = aws_iam_role.get_expired_users_sfn_exec_role.name
    policy_arn = aws_iam_policy.get_expired_users_sfn_policy.arn
}

resource "aws_sfn_state_machine" "expired_users_state_machine" {
    name = "ExpiredUsersKeyRotation"
    role_arn = aws_iam_role.get_expired_users_sfn_exec_role.arn

    definition = templatefile("./expired_users_sfn_defininition.tmpl", {
        get_expired_keys = aws_lambda_function.get_expired_users_lambda.arn
    })
}