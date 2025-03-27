import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table("Anomalies")

def lambda_handler(event, context):
    try:
        passport_no = json.loads(event['body'])['passport_no']
        response = table.scan(
            FilterExpression="passport_no = :p",
            ExpressionAttributeValues={":p": passport_no}
        )

        found = len(response.get("Items", [])) > 0
        return {
            "statusCode": 200,
            "body": json.dumps({"has_anomaly": found})
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
