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
      STAGE             = "dev"
      REFERENCE_BUCKET  = aws_s3_bucket.fingerprint_bucket.bucket
    }
  }

  layers = [
    aws_lambda_layer_version.fingerprint_layer.arn
  ]
}

resource "aws_lambda_layer_version" "fingerprint_layer" {
  layer_name          = "fingerprint_layer"
  filename            = "${path.root}/../lambda_layer/layer.zip"
  compatible_runtimes = ["python3.11"]
  description         = "Layer with numpy + opencv-python-headless"
  compatible_architectures = ["arm64"]
}

############################
# API Gateway
############################
resource "aws_api_gateway_rest_api" "fingerprint_api" {
  name        = "FingerprintAuthAPI"
  description = "API for fingerprint authentication"
}

resource "aws_api_gateway_resource" "verify_fingerprint_resource" {
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  parent_id   = aws_api_gateway_rest_api.fingerprint_api.root_resource_id
  path_part   = "verify-fingerprint"
}

# POST Method
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

resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id   = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id          = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id          = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method          = aws_api_gateway_method.options_method.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Add CORS headers to your POST method response
resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method = aws_api_gateway_method.verify_fingerprint_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  resource_id = aws_api_gateway_resource.verify_fingerprint_resource.id
  http_method = aws_api_gateway_method.verify_fingerprint_method.http_method
  status_code = aws_api_gateway_method_response.post_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# Update the deployment to depend on CORS setup
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.verify_fingerprint_integration,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.fingerprint_api.id
  stage_name  = "dev"
}
############################
# S3 Bucket for Fingerprints
############################
resource "aws_s3_bucket" "fingerprint_bucket" {
  bucket = "fingerprint-reference-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.fingerprint_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "reference_fingerprint" {
  bucket = aws_s3_bucket.fingerprint_bucket.id
  key    = "101_1.tif"
  source = "${path.root}/../DB1_B/101_1.tif"
  content_type = "image/tiff"
}

############################
# IAM Policy for Lambda to access S3
############################
data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.fingerprint_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda-s3-access-fingerprint"
  policy      = data.aws_iam_policy_document.lambda_s3_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

############################
# Outputs
############################
output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}/verify-fingerprint"
}