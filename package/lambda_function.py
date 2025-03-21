import json
import base64
import boto3
from fingerprint_matching import match_fingerprints

s3 = boto3.client('s3')
REFERENCE_BUCKET = 'your-reference-bucket'
REFERENCE_KEY = 'reference_fingerprint.png'

def get_reference_fingerprint():
    # Načti referenční otisk z S3
    obj = s3.get_object(Bucket=REFERENCE_BUCKET, Key=REFERENCE_KEY)
    return obj['Body'].read()

def lambda_handler(event, context):
    fingerprint_encoded = event['fingerprint_image']
    user_id = event['user_id']
    
    # Decode přijatého otisku
    received_image = base64.b64decode(fingerprint_encoded)
    
    # Načti referenční otisk
    reference_image = get_reference_fingerprint()
    
    # Porovnej otisky
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
