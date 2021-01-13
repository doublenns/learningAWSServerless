## Step Function deployment
resource "aws_iam_role" "get_expired_users_sfn_exec_role" {
  name = "SFN-${var.get_expired_users_lambda_name}"

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
  name        = "SFN-${var.get_expired_users_lambda_name}"
  path        = "/"
  description = "IAM policy for step function ${var.get_expired_users_lambda_name}"

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
  role       = aws_iam_role.get_expired_users_sfn_exec_role.name
  policy_arn = aws_iam_policy.get_expired_users_sfn_policy.arn
}

resource "aws_sfn_state_machine" "expired_users_state_machine" {
  name     = "ExpiredUsersKeyRotation"
  role_arn = aws_iam_role.get_expired_users_sfn_exec_role.arn

  definition = templatefile("./expired_users_sfn_defininition.tmpl", {
    get_expired_keys = aws_lambda_function.get_expired_users_lambda.arn
  })
}