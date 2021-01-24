## Get Expired Keys Lambda deployment
variable "get_expired_keys_lambda_name" {
  default = "GetExpiredKeys"
}

data "archive_file" "get_expired_keys_archive" {
  type        = "zip"
  source_file = "../lambda_source_code/get_expired_keys.py"
  output_path = "../lambda_source_code/get_expired_keys.zip"
}

resource "aws_lambda_function" "get_expired_keys_lambda" {
  filename         = "../lambda_source_code/get_expired_keys.zip"
  function_name    = var.get_expired_keys_lambda_name
  role             = aws_iam_role.get_expired_keys_lambda_exec_role.arn
  handler          = "get_expired_keys.get_expired_keys"
  timeout          = 120
  source_code_hash = data.archive_file.get_expired_keys_archive.output_base64sha256
  runtime          = "python3.8"
}

resource "aws_cloudwatch_log_group" "get_expired_keys_lambda-log_group" {
  name              = "/aws/lambda/${var.get_expired_keys_lambda_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "get_expired_keys_lambda_exec_role" {
  name = "Lambda-${var.get_expired_keys_lambda_name}"

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

resource "aws_iam_policy" "get_expired_keys_lambda_policy" {
  name        = "Lambda-${var.get_expired_keys_lambda_name}"
  path        = "/"
  description = "IAM policy for lambda ${var.get_expired_keys_lambda_name}"

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

resource "aws_iam_role_policy_attachment" "get_expired_keys_lambda_exec_role_attachment" {
  role       = aws_iam_role.get_expired_keys_lambda_exec_role.name
  policy_arn = aws_iam_policy.get_expired_keys_lambda_policy.arn
}
