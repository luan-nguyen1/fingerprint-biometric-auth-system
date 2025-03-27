variable "lambda_function_names" {
  type = map(string)
}

variable "lambda_invoke_arns" {
  type = map(string)
}

locals {
  routes = {
    "verify-fingerprint"     = "verify_fingerprint"
    "register-traveler"      = "upload_documents"
    "extract-face-info"      = "extract_face_info"
    "traveler-history"       = "traveler_history"
    "boarding-pass"          = "scan_boarding_pass"
    "global-entry"           = "check_global_entry"
    "anomaly-check"          = "anomaly_check"
    "admin-config"           = "config_admin"
    "access-logs"            = "access_logs"
    "extract-passport"       = "generate_upload_url" # ✅ přidáno!
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "FingerprintAuthAPI"
  description = "API for biometric border control"
}

resource "aws_api_gateway_resource" "resources" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "post_methods" {
  for_each      = local.routes
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resources[each.key].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_integrations" {
  for_each                = local.routes
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resources[each.key].id
  http_method             = "POST"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns[each.value]
}

resource "aws_api_gateway_method" "options_methods" {
  for_each      = local.routes
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resources[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integrations" {
  for_each                = local.routes
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resources[each.key].id
  http_method             = "OPTIONS"
  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }

  depends_on = [aws_api_gateway_method.options_methods]
}

resource "aws_api_gateway_method_response" "options_responses" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resources[each.key].id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_method.options_methods]
}

resource "aws_api_gateway_integration_response" "options_integration_responses" {
  for_each    = local.routes
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resources[each.key].id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_method_response.options_responses]
}

resource "aws_lambda_permission" "allow_api_gateway" {
  for_each      = local.routes
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names[each.value]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.post_integrations,
    aws_api_gateway_integration_response.options_integration_responses
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"

  triggers = {
    redeploy_hash = sha1(jsonencode(local.routes))
  }
}

output "endpoint" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
