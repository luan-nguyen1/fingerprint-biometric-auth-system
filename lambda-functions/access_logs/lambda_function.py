import boto3
import os
import json
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table("AccessLogs")

def lambda_handler(event, context):
    try:
        # Optional filter
        passport_no = json.loads(event['body']).get('passport_no')

        if passport_no:
            response = table.scan(
                FilterExpression="passport_no = :p",
                ExpressionAttributeValues={":p": passport_no}
            )
        else:
            response = table.scan()

        logs = sorted(response.get('Items', []), key=lambda x: x.get('timestamp', ''), reverse=True)

        return {
            "statusCode": 200,
            "body": json.dumps({"logs": logs})
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
