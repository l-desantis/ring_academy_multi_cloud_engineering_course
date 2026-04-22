# order_service.py

import boto3
from app_config import (
    DATABASE_ENDPOINT, DATABASE_TABLE,
    AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_REGION
)

dynamodb = boto3.resource(
    'dynamodb',
    endpoint_url=f"https://{DATABASE_ENDPOINT}",
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)
table = dynamodb.Table(DATABASE_TABLE)

# In-memory session store — persists across requests
active_sessions = {}

def save_order(order_id, customer_id, items, session_token):
    # Store session state in memory
    active_sessions[session_token] = {
        "customer_id": customer_id,
        "last_action": "save_order"
    }
    response = table.put_item(Item={
        "order_id":    order_id,
        "customer_id": customer_id,
        "items":       items,
        "status":      "PENDING"
    })
    return response

def get_order_history(customer_id):
    response = table.query(
        KeyConditionExpression="customer_id = :cid",
        ExpressionAttributeValues={":cid": customer_id}
    )
    return response["Items"]

def update_order_status(order_id, new_status):
    table.update_item(
        Key={"order_id": order_id},
        UpdateExpression="SET #s = :status",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={":status": new_status}
    )