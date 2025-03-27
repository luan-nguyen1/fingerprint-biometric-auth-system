import json
import boto3
import os
import pytesseract
from PIL import Image
import tempfile

s3 = boto3.client('s3')
BUCKET = os.environ['BUCKET_NAME']

def extract_info_from_image(image_path):
    text = pytesseract.image_to_string(Image.open(image_path))
    
    name = None
    passport_no = None

    # Jednoduchá heuristika (doladíme podle OCR výsledků)
    for line in text.splitlines():
        if "Name" in line:
            name = line.split(":")[-1].strip()
        if "Passport" in line or "No" in line:
            passport_no = line.split()[-1].strip()
    
    return name, passport_no

def lambda_handler(event, context):
    try:
        body = json.loads(event["body"])
        key = body["passport_s3_key"]

        with tempfile.NamedTemporaryFile(suffix=".jpg") as tmp:
            s3.download_file(BUCKET, key, tmp.name)
            name, passport_no = extract_info_from_image(tmp.name)

        if not name or not passport_no:
            raise ValueError("Extraction failed")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "name": name,
                "passport_no": passport_no
            })
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
