from app import app

def handler(event, context):
    return {
        'statusCode': 200,
        'body': app.test_client().get('/').data.decode('utf-8'),
        'headers': {
            'Content-Type': 'application/json'
        }
    }