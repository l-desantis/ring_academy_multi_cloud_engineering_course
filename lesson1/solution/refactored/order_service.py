import os
from adapters.dynamodb_order_repository import DynamoDBOrderRepository
from ports.order_repository import OrderRepository

# Dependency injection — swap this line for FirestoreOrderRepository to migrate to GCP
repository: OrderRepository = DynamoDBOrderRepository(
    table_name=os.environ["DATABASE_TABLE"],
    region=os.environ["AWS_REGION"]
)

def save_order(order_id: str, customer_id: str, items: list) -> None:
    repository.save({
        "order_id":    order_id,
        "customer_id": customer_id,
        "items":       items,
        "status":      "PENDING"
    })

def get_order_history(customer_id: str) -> list:
    return repository.find_by_customer(customer_id)

def update_order_status(order_id: str, new_status: str) -> None:
    repository.update_status(order_id, new_status)