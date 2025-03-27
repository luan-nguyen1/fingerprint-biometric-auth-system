resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role_border_control"

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

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

##############################
# S3 Access Policy (Read/Write)
##############################
data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::fingerprint-reference-*/*"
    ]
  }
}

resource "aws_iam_policy" "s3_policy" {
  name   = "lambda-s3-access"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

##############################
# DynamoDB Access Policy (Read/Write)
##############################
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/TravelerMetadata"
    ]
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name   = "lambda-dynamodb-access"
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "ddb_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

##############################
# SSM
##############################
data "aws_iam_policy_document" "ssm_access" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/bordercontrol/config/*"
    ]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name   = "lambda-ssm-access"
  policy = data.aws_iam_policy_document.ssm_access.json
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

##############################
# Rekognition
##############################
data "aws_iam_policy_document" "rekognition_access" {
  statement {
    actions = [
      "rekognition:DetectFaces"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rekognition_policy" {
  name   = "lambda-rekognition-access"
  policy = data.aws_iam_policy_document.rekognition_access.json
}

resource "aws_iam_role_policy_attachment" "rekognition_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.rekognition_policy.arn
}

##############################
# Output
##############################
output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}
