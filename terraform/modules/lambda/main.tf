variable "lambda_exec_role_arn" {}
variable "bucket_name" {}
variable "traveler_table" {}

resource "aws_lambda_function" "verify_fingerprint" {
  function_name    = "verify_fingerprint"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/verify_fingerprint/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/verify_fingerprint/lambda_function.zip")
  timeout          = 15

  environment {
    variables = {
      STAGE            = "dev"
      REFERENCE_BUCKET = var.bucket_name
      TRAVELER_TABLE   = var.traveler_table
    }
  }

  layers = [aws_lambda_layer_version.fingerprint_layer.arn]
}

resource "aws_lambda_function" "upload_documents" {
  function_name    = "upload_documents"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/upload_documents/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/upload_documents/lambda_function.zip")
  timeout          = 10

  environment {
    variables = {
      STAGE          = "dev"
      BUCKET_NAME    = var.bucket_name
      TRAVELER_TABLE = var.traveler_table
    }
  }
}

resource "aws_lambda_function" "extract_face_info" {
  function_name    = "extract_face_info"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/extract_face_info/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/extract_face_info/lambda_function.zip")
  timeout          = 10
}

resource "aws_lambda_function" "traveler_history" {
  function_name    = "traveler_history"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/traveler_history/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/traveler_history/lambda_function.zip")
  timeout          = 10
}

resource "aws_lambda_function" "scan_boarding_pass" {
  function_name    = "scan_boarding_pass"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/scan_boarding_pass/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/scan_boarding_pass/lambda_function.zip")
  timeout          = 5
}

resource "aws_lambda_function" "check_global_entry" {
  function_name    = "check_global_entry"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/check_global_entry/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/check_global_entry/lambda_function.zip")
  timeout          = 5
}

resource "aws_lambda_function" "anomaly_check" {
  function_name    = "anomaly_check"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/anomaly_check/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/anomaly_check/lambda_function.zip")
  timeout          = 10
}

resource "aws_lambda_function" "config_admin" {
  function_name    = "config_admin"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/config_admin/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/config_admin/lambda_function.zip")
  timeout          = 5
}

resource "aws_lambda_function" "access_logs" {
  function_name    = "access_logs"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/access_logs/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/access_logs/lambda_function.zip")
  timeout          = 10
}

resource "aws_lambda_function" "generate_upload_url" {
  function_name    = "generate_upload_url"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/generate_upload_url/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/generate_upload_url/lambda_function.zip")
  timeout          = 10

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
    }
  }
}

resource "aws_lambda_function" "extract_passport_info" {
  function_name    = "extract_passport_info"
  role             = var.lambda_exec_role_arn
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../../lambda-functions/extract_passport_info/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../lambda-functions/extract_passport_info/lambda_function.zip")
  timeout          = 15

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
    }
  }
}

resource "aws_lambda_layer_version" "fingerprint_layer" {
  layer_name               = "fingerprint_layer"
  filename                 = "${path.module}/../../../lambda_layer/layer.zip"
  compatible_runtimes      = ["python3.11"]
  compatible_architectures = ["arm64"]
  description              = "Layer with numpy + opencv-python-headless"
}


output "verify_fingerprint_invoke_arn" {
  value = aws_lambda_function.verify_fingerprint.invoke_arn
}
output "verify_fingerprint_function_name" {
  value = aws_lambda_function.verify_fingerprint.function_name
}

output "upload_documents_invoke_arn" {
  value = aws_lambda_function.upload_documents.invoke_arn
}
output "upload_documents_function_name" {
  value = aws_lambda_function.upload_documents.function_name
}

output "extract_face_info_invoke_arn" {
  value = aws_lambda_function.extract_face_info.invoke_arn
}
output "extract_face_info_function_name" {
  value = aws_lambda_function.extract_face_info.function_name
}

output "traveler_history_invoke_arn" {
  value = aws_lambda_function.traveler_history.invoke_arn
}
output "traveler_history_function_name" {
  value = aws_lambda_function.traveler_history.function_name
}

output "scan_boarding_pass_invoke_arn" {
  value = aws_lambda_function.scan_boarding_pass.invoke_arn
}
output "scan_boarding_pass_function_name" {
  value = aws_lambda_function.scan_boarding_pass.function_name
}

output "check_global_entry_invoke_arn" {
  value = aws_lambda_function.check_global_entry.invoke_arn
}
output "check_global_entry_function_name" {
  value = aws_lambda_function.check_global_entry.function_name
}

output "anomaly_check_invoke_arn" {
  value = aws_lambda_function.anomaly_check.invoke_arn
}
output "anomaly_check_function_name" {
  value = aws_lambda_function.anomaly_check.function_name
}

output "config_admin_invoke_arn" {
  value = aws_lambda_function.config_admin.invoke_arn
}
output "config_admin_function_name" {
  value = aws_lambda_function.config_admin.function_name
}

output "access_logs_invoke_arn" {
  value = aws_lambda_function.access_logs.invoke_arn
}
output "access_logs_function_name" {
  value = aws_lambda_function.access_logs.function_name
}

output "generate_upload_url_invoke_arn" {
  value = aws_lambda_function.generate_upload_url.invoke_arn
}
output "generate_upload_url_function_name" {
  value = aws_lambda_function.generate_upload_url.function_name
}

output "extract_passport_info_invoke_arn" {
  value = aws_lambda_function.extract_passport_info.invoke_arn
}

output "extract_passport_info_function_name" {
  value = aws_lambda_function.extract_passport_info.function_name
}