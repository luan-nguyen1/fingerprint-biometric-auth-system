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
    print("Received event:", json.dumps(event))
    
    # Base CORS headers
    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST',
        'Content-Type': 'application/json'
    }

    # Handle CORS preflight request
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({'message': 'CORS preflight response'})
        }

    try:
        # Handle both direct Lambda invocation and API Gateway proxy
        body = event.get('body', event)
        if isinstance(body, str):
            body = json.loads(body)
        
        print("Body parsed:", body)
        fingerprint_encoded = body['fingerprint_image']
        user_id = body.get('user_id', 'user_001')
        
        print("Decoding base64 image...")
        received_image = base64.b64decode(fingerprint_encoded)
        print("Fetching reference image from S3...")
        reference_image = get_reference_fingerprint()
        print("Matching fingerprints...")
        is_match, score = match_fingerprints(reference_image, received_image)
        
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({
                'user_id': user_id,
                'match': is_match,
                'score': score
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers,  # Ensure CORS headers in errors
            'body': json.dumps({
                'error': str(e),
                'message': 'Error processing fingerprint'
            })
        }