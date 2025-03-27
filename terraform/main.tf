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

module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source = "./modules/s3"
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "lambda" {
  source                 = "./modules/lambda"
  lambda_exec_role_arn  = module.iam.lambda_exec_role_arn
  bucket_name           = module.s3.bucket_name
  traveler_table        = module.dynamodb.table_name
}

module "api_gateway" {
  source = "./modules/api_gateway"

  lambda_invoke_arns = {
    verify_fingerprint   = module.lambda.verify_fingerprint_invoke_arn
    upload_documents     = module.lambda.upload_documents_invoke_arn
    extract_face_info    = module.lambda.extract_face_info_invoke_arn
    traveler_history     = module.lambda.traveler_history_invoke_arn
    scan_boarding_pass   = module.lambda.scan_boarding_pass_invoke_arn
    check_global_entry   = module.lambda.check_global_entry_invoke_arn
    anomaly_check        = module.lambda.anomaly_check_invoke_arn
    config_admin         = module.lambda.config_admin_invoke_arn
    access_logs          = module.lambda.access_logs_invoke_arn
    generate_upload_url  = module.lambda.generate_upload_url_invoke_arn 
    extract_passport_info = module.lambda.extract_passport_info_invoke_arn
  }

  lambda_function_names = {
    verify_fingerprint   = module.lambda.verify_fingerprint_function_name
    upload_documents     = module.lambda.upload_documents_function_name
    extract_face_info    = module.lambda.extract_face_info_function_name
    traveler_history     = module.lambda.traveler_history_function_name
    scan_boarding_pass   = module.lambda.scan_boarding_pass_function_name
    check_global_entry   = module.lambda.check_global_entry_function_name
    anomaly_check        = module.lambda.anomaly_check_function_name
    config_admin         = module.lambda.config_admin_function_name
    access_logs          = module.lambda.access_logs_function_name
    generate_upload_url  = module.lambda.generate_upload_url_function_name 
    extract_passport_info = module.lambda.extract_passport_info_function_name
  }
}

output "api_endpoint" {
  value       = module.api_gateway.endpoint
  description = "API Gateway invoke URL"
}
