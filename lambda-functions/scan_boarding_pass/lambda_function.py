import json

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        barcode = body.get('barcode')

        # Simulovaný parsing
        info = {
            "boarding_id": "ABC123456",
            "flight": "OK432",
            "destination": "Prague",
            "departure_time": "2025-04-01T10:45:00Z"
        }

        return {
            "statusCode": 200,
            "body": json.dumps(info)
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
