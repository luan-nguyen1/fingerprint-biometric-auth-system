import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TRAVELER_TABLE'])

def lambda_handler(event, context):
    try:
        passport_no = json.loads(event['body'])['passport_no']
        response = table.get_item(Key={'passport_no': passport_no})
        item = response.get('Item')

        if not item:
            return {'statusCode': 404, 'body': json.dumps({'error': 'Traveler not found'})}

        return {
            'statusCode': 200,
            'body': json.dumps({
                'passport_no': passport_no,
                'name': item.get('name'),
                'history': item.get('history', [])
            })
        }

    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
