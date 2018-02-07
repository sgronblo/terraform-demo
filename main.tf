resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch_write_access" {
  role = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "${path.module}/lambda.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "employee_listing" {
    function_name = "employee-listing-lambda"
    filename = "${data.archive_file.lambda_zip.output_path}"
    runtime = "nodejs6.10"
    handler = "lambda.handler"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
}