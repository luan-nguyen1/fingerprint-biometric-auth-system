import json
import base64
import boto3
import os
import traceback

s3 = boto3.client('s3')
REFERENCE_BUCKET = os.environ['REFERENCE_BUCKET']
REFERENCE_KEY = '101_1.tif'

def get_reference_fingerprint():
    try:
        obj = s3.get_object(Bucket=REFERENCE_BUCKET, Key=REFERENCE_KEY)
        print(f"Successfully fetched reference image from S3: {REFERENCE_BUCKET}/{REFERENCE_KEY}")
        return obj['Body'].read()
    except Exception as e:
        print(f"Error fetching reference fingerprint from S3: {str(e)}")
        raise

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    
    # Base CORS headers (always returned)
    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST',
        'Content-Type': 'application/json'
    }

    # Handle CORS preflight request
    if event.get('httpMethod') == 'OPTIONS':
        print("Handling OPTIONS preflight request")
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({'message': 'CORS preflight response'})
        }

    try:
        # Handle both direct invocation and API Gateway proxy
        body = event.get('body', event)
        if isinstance(body, str):
            print("Parsing body as string")
            body = json.loads(body)
        else:
            print("Body is already a dict")

        print("Body parsed:", json.dumps(body))
        fingerprint_encoded = body.get('fingerprint_image')
        if not fingerprint_encoded:
            raise ValueError("Missing 'fingerprint_image' in request body")
        
        user_id = body.get('user_id', 'user_001')
        print(f"User ID: {user_id}")

        # Decode base64 with padding check
        print("Decoding base64 image...")
        try:
            # Ensure proper padding
            missing_padding = len(fingerprint_encoded) % 4
            if missing_padding:
                fingerprint_encoded += '=' * (4 - missing_padding)
            received_image = base64.b64decode(fingerprint_encoded)
            print("Base64 decoding successful")
        except Exception as e:
            raise ValueError(f"Base64 decoding failed: {str(e)}")

        print("Fetching reference image from S3...")
        reference_image = get_reference_fingerprint()

        print("Matching fingerprints...")
        # Assuming match_fingerprints exists in the layer or code
        from fingerprint_matching import match_fingerprints
        is_match, score = match_fingerprints(reference_image, received_image)
        print(f"Fingerprint match result: is_match={is_match}, score={score}")

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
        print(f"Error in Lambda execution: {str(e)}")
        print("Traceback:", traceback.format_exc())
        return {
            'statusCode': 500,
            'headers': cors_headers,  # CORS headers even on error
            'body': json.dumps({
                'error': str(e),
                'message': 'Error processing fingerprint',
                'traceback': traceback.format_exc()
            })
        }