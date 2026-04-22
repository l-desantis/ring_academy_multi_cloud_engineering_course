import boto3
from ports.order_repository import OrderRepository

class DynamoDBOrderRepository(OrderRepository):

    def __init__(self, table_name: str, region: str):
        self.table = boto3.resource(
            'dynamodb', region_name=region
        ).Table(table_name)

    def save(self, order: dict) -> None:
        self.table.put_item(Item=order)

    def find_by_customer(self, customer_id: str) -> list:
        response = self.table.query(
            KeyConditionExpression="customer_id = :cid",
            ExpressionAttributeValues={":cid": customer_id}
        )
        return response["Items"]

    def update_status(self, order_id: str, status: str) -> None:
        self.table.update_item(
            Key={"order_id": order_id},
            UpdateExpression="SET #s = :status",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":status": status}
        )