import boto3
import base64
import json
import uuid
import os
from datetime import datetime

s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')

BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        image_data = body['image']  # base64 string

        image_bytes = base64.b64decode(image_data.split(',')[-1])
        image_id = str(uuid.uuid4())
        key = f"faces/{image_id}.jpg"

        # Upload to S3
        s3.put_object(Bucket=BUCKET, Key=key, Body=image_bytes, ContentType='image/jpeg')

        # Rekognition Call
        response = rekognition.detect_faces(
            Image={'S3Object': {'Bucket': BUCKET, 'Name': key}},
            Attributes=['ALL']
        )

        if not response['FaceDetails']:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'No face detected'})
            }

        face = response['FaceDetails'][0]
        result = {
            'age_range': face['AgeRange'],
            'gender': face['Gender']['Value'],
            'smile': face['Smile']['Value'],
            'glasses': face['Eyeglasses']['Value'],
            'emotions': sorted(face['Emotions'], key=lambda e: e['Confidence'], reverse=True)
        }

        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
