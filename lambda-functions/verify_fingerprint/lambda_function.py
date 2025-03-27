import json
import base64
import boto3
import os
import traceback
from boto3.dynamodb.conditions import Key

# AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment variables
REFERENCE_BUCKET = os.environ['REFERENCE_BUCKET']
TRAVELER_TABLE = os.environ['TRAVELER_TABLE']

def get_reference_fingerprint(s3_key):
    try:
        obj = s3.get_object(Bucket=REFERENCE_BUCKET, Key=s3_key)
        print(f"Fetched reference image: {s3_key}")
        return obj['Body'].read()
    except Exception as e:
        raise RuntimeError(f"Failed to fetch reference image from S3: {e}")

def get_traveler_metadata(passport_no):
    try:
        table = dynamodb.Table(TRAVELER_TABLE)
        response = table.get_item(Key={"passport_no": passport_no})
        if "Item" not in response:
            raise KeyError(f"Traveler with passport {passport_no} not found.")
        return response["Item"]
    except Exception as e:
        raise RuntimeError(f"Failed to retrieve traveler metadata: {e}")

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST',
        'Content-Type': 'application/json'
    }

    if event.get('httpMethod') == 'OPTIONS':
        print("Handling CORS preflight")
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({'message': 'CORS preflight accepted'})
        }

    try:
        body = event.get('body', event)
        if isinstance(body, str):
            body = json.loads(body)

        fingerprint_encoded = body.get('fingerprint_image')
        passport_no = body.get('passport_no')

        if not fingerprint_encoded or not passport_no:
            raise ValueError("Missing 'fingerprint_image' or 'passport_no' in request.")

        # Lookup traveler in DynamoDB
        traveler = get_traveler_metadata(passport_no)
        reference_key = traveler["reference_key"]
        user_id = traveler["user_id"]
        name = traveler["name"]

        print(f"Verifying passport {passport_no} (User: {name}, ID: {user_id})")

        # Decode base64
        missing_padding = len(fingerprint_encoded) % 4
        if missing_padding:
            fingerprint_encoded += '=' * (4 - missing_padding)
        received_image = base64.b64decode(fingerprint_encoded)

        # Load reference fingerprint
        reference_image = get_reference_fingerprint(reference_key)

        # Match using OpenCV in Lambda layer
        from fingerprint_matching import match_fingerprints
        is_match, score = match_fingerprints(reference_image, received_image)

        print(f"Match result: {is_match} | Score: {score}")

        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({
                'match': is_match,
                'score': score,
                'user_id': user_id,
                'name': name,
                'passport_no': passport_no
            })
        }

    except Exception as e:
        print("Error occurred:", str(e))
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to verify traveler.',
                'traceback': traceback.format_exc()
            })
        }
