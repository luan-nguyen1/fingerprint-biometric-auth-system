#####################
# Traveler Metadata
#####################
resource "aws_dynamodb_table" "traveler_metadata" {
  name         = "TravelerMetadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "passport_no"

  attribute {
    name = "passport_no"
    type = "S"
  }

  tags = {
    Project = "BorderControl"
  }
}

#####################
# Boarding Passes
#####################
resource "aws_dynamodb_table" "boarding_passes" {
  name         = "BoardingPasses"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "boarding_id"

  attribute {
    name = "boarding_id"
    type = "S"
  }

  tags = {
    Project = "BorderControl"
  }
}

#####################
# Access Logs
#####################
resource "aws_dynamodb_table" "access_logs" {
  name         = "AccessLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = {
    Project = "BorderControl"
  }
}

#####################
# Anomalies
#####################
resource "aws_dynamodb_table" "anomalies" {
  name         = "Anomalies"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incident_id"

  attribute {
    name = "incident_id"
    type = "S"
  }

  tags = {
    Project = "BorderControl"
  }
}

#####################
# Activity Feed
#####################
resource "aws_dynamodb_table" "activity_feed" {
  name         = "ActivityFeed"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "activity_id"

  attribute {
    name = "activity_id"
    type = "S"
  }

  tags = {
    Project = "BorderControl"
  }
}

#####################
# Outputs
#####################
output "table_name" {
  value = aws_dynamodb_table.traveler_metadata.name
}

output "boarding_table_name" {
  value = aws_dynamodb_table.boarding_passes.name
}

output "access_logs_table_name" {
  value = aws_dynamodb_table.access_logs.name
}

output "anomalies_table_name" {
  value = aws_dynamodb_table.anomalies.name
}

output "activity_feed_table_name" {
  value = aws_dynamodb_table.activity_feed.name
}
