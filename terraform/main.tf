terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  # profile = "default" # pokud máš nějaký named profile
}

############################
# IAM Role for Lambda
############################
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role_fingerprint"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Přidáme základní policy pro logy
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

############################
# Lambda Function
############################
resource "aws_lambda_function" "verify_fingerprint" {
  function_name    = "verify_fingerprint"
  role             = aws_iam_role.lambda_exec_role.arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.root}/../lambda_function.zip"
  source_code_hash = filebase64sha256("${path.root}/../lambda_function.zip")

  environment {
    variables = {
      STAGE = "dev"
    }
  }

  layers = [aws_lambda_layer_version.opencv_layer.arn]
}

resource "aws_lambda_layer_version" "opencv_layer" {
  layer_name          = "opencv_layer"
  filename            = "${path.root}/../lambda_layer/layer.zip"
  compatible_runtimes = ["python3.11"]
  description         = "Layer with opencv-python-headless and numpy>=1.24.0 - updated on 2025-03-21T19:50"
}

############################
# API Gateway
############################
resource "aws_api_gateway_rest_api" "fingerprint_api" {
  name        = "FingerprintAuthAPI"
  description = "API for fingerprint authentication"
}

# Resource: /verify-fingerprint
resource "aws_api_gateway_resource" "verify_fingerprint_resource" {
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  parent_id   = aws_api_gateway_rest_api.fingerprint_api.root_resource_id
  path_part   = "verify-fingerprint"
}

resource "aws_api_gateway_method" "verify_fingerprint_method" {
  rest_api_id   = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id   = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "verify_fingerprint_integration" {
  rest_api_id             = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id             = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method             = aws_api_gateway_method.verify_fingerprint_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.verify_fingerprint.invoke_arn
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_fingerprint.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fingerprint_api.execution_arn}/*/*"
}

# Deployment + Stage
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.verify_fingerprint_integration]
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  stage_name  = "dev"
}

############################
# Outputs
############################
output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = "${aws_api_gateway_rest_api.fingerprint_api.execution_arn}"
}
