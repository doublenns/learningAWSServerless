## Process Expired Keys Lambda deployment
variable "process_expired_keys_lambda_name" {
  default = "ProcessExpiredKeys"
}

data "archive_file" "process_expired_keys_archive" {
  type        = "zip"
  source_file = "../lambda_source_code/process_expired_keys.py"
  output_path = "../lambda_source_code/process_expired_keys.zip"
}

resource "aws_lambda_function" "process_expired_keys_lambda" {
  filename         = "../lambda_source_code/process_expired_keys.zip"
  function_name    = var.process_expired_keys_lambda_name
  role             = aws_iam_role.process_expired_keys_lambda_exec_role.arn
  handler          = "process_expired_keys.process_expired_keys"
  timeout          = 120
  source_code_hash = data.archive_file.process_expired_keys_archive.output_base64sha256
  runtime          = "python3.8"
}

resource "aws_cloudwatch_log_group" "process_expired_keys_lambda-log_group" {
  name              = "/aws/lambda/${var.process_expired_keys_lambda_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "process_expired_keys_lambda_exec_role" {
  name = "Lambda-${var.process_expired_keys_lambda_name}"

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

resource "aws_iam_policy" "process_expired_keys_lambda_policy" {
  name        = "Lambda-${var.process_expired_keys_lambda_name}"
  path        = "/"
  description = "IAM policy for lambda ${var.process_expired_keys_lambda_name}"

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
                "iam:ListUserTags",
                # "iam:ListAccessKeys"
                "iam:UpdateAccessKey"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "process_expired_keys_lambda_exec_role_attachment" {
  role       = aws_iam_role.process_expired_keys_lambda_exec_role.name
  policy_arn = aws_iam_policy.process_expired_keys_lambda_policy.arn
}
