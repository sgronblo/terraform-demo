resource "aws_iam_role" "apigw_cw_role" {
  name = "apigw_cw_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "apigw_cw_write_access" {
  role = "${aws_iam_role.apigw_cw_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

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

resource "aws_api_gateway_account" "api_gw_account" {
  cloudwatch_role_arn = "${aws_iam_role.apigw_cw_role.arn}"
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

resource "aws_api_gateway_rest_api" "rj_api" {
  name = "RJ Employees API"
  description = "Manages the employees of RJ"
}

resource "aws_api_gateway_resource" "employees" {
  rest_api_id = "${aws_api_gateway_rest_api.rj_api.id}"
  parent_id = "${aws_api_gateway_rest_api.rj_api.root_resource_id}"
  path_part = "employees"
}

resource "aws_api_gateway_method" "list_all" {
  rest_api_id = "${aws_api_gateway_rest_api.rj_api.id}"
  resource_id = "${aws_api_gateway_resource.employees.id}"
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "rj_api_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.rj_api.id}"
  resource_id = "${aws_api_gateway_resource.employees.id}"
  http_method = "${aws_api_gateway_method.list_all.http_method}"
  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/${aws_lambda_function.employee_listing.arn}/invocations"
}

resource "aws_api_gateway_deployment" "rj_api_integration" {
  depends_on = ["aws_api_gateway_integration.rj_api_integration"]

  rest_api_id = "${aws_api_gateway_rest_api.rj_api.id}"
  stage_name  = "test"
}

data "aws_caller_identity" "current" {}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.employee_listing.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:ap-northeast-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.rj_api.id}/*/${aws_api_gateway_method.list_all.http_method}${aws_api_gateway_resource.employees.path}"
}