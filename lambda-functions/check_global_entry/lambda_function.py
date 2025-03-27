import json

WHITELIST = {"CZ1234567", "SK7654321"}

def lambda_handler(event, context):
    try:
        passport_no = json.loads(event['body'])['passport_no']
        is_registered = passport_no in WHITELIST

        return {
            "statusCode": 200,
            "body": json.dumps({"global_entry": is_registered})
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
