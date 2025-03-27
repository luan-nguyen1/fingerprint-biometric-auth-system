import boto3
import os
import json
import base64
from requests_toolbelt.multipart import decoder

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

BUCKET = os.environ['BUCKET_NAME']
TRAVELER_TABLE = os.environ['TRAVELER_TABLE']
table = dynamodb.Table(TRAVELER_TABLE)

def lambda_handler(event, context):
    try:
        content_type = event['headers'].get('Content-Type') or event['headers'].get('content-type')
        body = base64.b64decode(event['body']) if event.get('isBase64Encoded', False) else event['body']

        multipart_data = decoder.MultipartDecoder(body, content_type)

        # Parse parts
        fields = {}
        for part in multipart_data.parts:
            content_disposition = part.headers[b'Content-Disposition'].decode()
            name = content_disposition.split('name="')[1].split('"')[0]
            fields[name] = part

        # Extract fields
        name = fields['name'].text
        passport_no = fields['passport_no'].text
        passport_img = fields['passport_image'].content
        fingerprint_img = fields['fingerprint_image'].content

        passport_key = f"passports/{passport_no}.jpg"
        fingerprint_key = f"fingerprints/{passport_no}.tif"

        s3.put_object(Bucket=BUCKET, Key=passport_key, Body=passport_img, ContentType='image/jpeg')
        s3.put_object(Bucket=BUCKET, Key=fingerprint_key, Body=fingerprint_img, ContentType='image/tiff')

        table.put_item(Item={
            'passport_no': passport_no,
            'name': name,
            'passport_s3_key': passport_key,
            'fingerprint_s3_key': fingerprint_key
        })

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Traveler registered successfully",
                "passport_no": passport_no,
                "name": name,
                "passport_s3_key": passport_key,
                "fingerprint_s3_key": fingerprint_key
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
