import boto3
import os
import json

ssm = boto3.client('ssm')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        mode = body.get('mode')  # "get" or "set"
        key = body['key']
        value = body.get('value')

        param_name = f"/bordercontrol/config/{key}"

        if mode == "get":
            param = ssm.get_parameter(Name=param_name)
            return {
                "statusCode": 200,
                "body": json.dumps({"key": key, "value": param['Parameter']['Value']})
            }

        elif mode == "set":
            ssm.put_parameter(Name=param_name, Value=value, Overwrite=True)
            return {
                "statusCode": 200,
                "body": json.dumps({"message": f"{key} updated"})
            }

        return {"statusCode": 400, "body": json.dumps({"error": "Invalid mode"})}

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
