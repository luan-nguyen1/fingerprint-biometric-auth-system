import json
import base64
import boto3
import logging
from fingerprint_matching import match_fingerprints

# Logger setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# S3 config
s3 = boto3.client('s3')
REFERENCE_BUCKET = 'your-reference-bucket'
REFERENCE_KEY = 'reference_fingerprint.png'

def get_reference_fingerprint():
    try:
        logger.info("Fetching reference fingerprint from S3...")
        obj = s3.get_object(Bucket=REFERENCE_BUCKET, Key=REFERENCE_KEY)
        return obj['Body'].read()
    except Exception as e:
        logger.error(f"Failed to fetch reference fingerprint: {e}")
        raise

def lambda_handler(event, context):
    logger.info("Lambda triggered with event: %s", json.dumps(event))

    try:
        fingerprint_encoded = event['fingerprint_image']
        user_id = event['user_id']
    except KeyError as e:
        logger.error(f"Missing key in event: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f"Missing key: {str(e)}"})
        }

    try:
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

    except Exception as e:
        logger.error(f"Error processing fingerprint: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
