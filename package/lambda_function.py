import json
import base64
import boto3
from fingerprint_matching import match_fingerprints
import os

s3 = boto3.client('s3')
REFERENCE_BUCKET = os.environ['REFERENCE_BUCKET']
REFERENCE_KEY = '101_1.tif'

def get_reference_fingerprint():
    obj = s3.get_object(Bucket=REFERENCE_BUCKET, Key=REFERENCE_KEY)
    return obj['Body'].read()

def lambda_handler(event, context):
    print("🔍 Raw event:", event)

    # ✅ Pokud přichází JSON string z API Gateway
    body = event.get("body")
    if body:
        body = json.loads(body)
    else:
        body = event

    fingerprint_encoded = body['fingerprint_image']
    user_id = body['user_id']

    received_image = base64.b64decode(fingerprint_encoded)
    reference_image = get_reference_fingerprint()
    is_match, score = match_fingerprints(reference_image, received_image)

    result = {
        'user_id': user_id,
        'match': is_match,
        'score': score
    }

    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
