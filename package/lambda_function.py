# lambda-functions/generate_upload_url/lambda_function.py
import json
import boto3
import os
import uuid

s3 = boto3.client('s3')
BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        passport_no = body['passport_no']

        # Generate unique keys
        passport_key = f"passports/{passport_no}-{uuid.uuid4()}.jpg"
        fingerprint_key = f"fingerprints/{passport_no}-{uuid.uuid4()}.tif"

        # Create presigned URLs
        passport_url = s3.generate_presigned_url(
            ClientMethod='put_object',
            Params={'Bucket': BUCKET, 'Key': passport_key, 'ContentType': 'image/jpeg'},
            ExpiresIn=300
        )

        fingerprint_url = s3.generate_presigned_url(
            ClientMethod='put_object',
            Params={'Bucket': BUCKET, 'Key': fingerprint_key, 'ContentType': 'image/tiff'},
            ExpiresIn=300
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'passport_url': passport_url,
                'passport_key': passport_key,
                'fingerprint_url': fingerprint_url,
                'fingerprint_key': fingerprint_key,
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
