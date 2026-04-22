# Audit Solution — 12-Factor Violations

## Step 1 — The 6 Violations

| Factor # | Factor Name | Violation | File | Severity |
|----------|-------------|-----------|------|----------|
| #3 | Config | AWS credentials and endpoints hardcoded | app_config.py | High |
| #3 | Config | Credentials baked into Docker image as ENV | Dockerfile | High |
| #4 | Backing Services | `import boto3` directly in business logic — no ACL | order_service.py | High |
| #6 | Processes | `active_sessions = {}` — in-memory state across requests | order_service.py | High |
| #11 | Logs | Logs written to local file, not stdout | logger.py | Medium |
| #5 | Build/Release/Run | Manual SSH deploy, no CI/CD, staging config in separate hardcoded file | deployment_notes.md | High |

---

## Step 3 — ACL Solution

```python
# ports/order_repository.py
from abc import ABC, abstractmethod

class OrderRepository(ABC):
    @abstractmethod
    def save(self, order: dict) -> None: ...
    @abstractmethod
    def find_by_customer(self, customer_id: str) -> list: ...
    @abstractmethod
    def update_status(self, order_id: str, status: str) -> None: ...

# adapters/dynamodb_order_repository.py
import boto3
from ports.order_repository import OrderRepository

class DynamoDBOrderRepository(OrderRepository):
    def __init__(self, table_name: str, region: str):
        self.table = boto3.resource('dynamodb', region_name=region).Table(table_name)

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

# adapters/firestore_order_repository.py — GCP migration target
from google.cloud import firestore
from ports.order_repository import OrderRepository

class FirestoreOrderRepository(OrderRepository):
    def __init__(self, collection: str):
        self.db = firestore.Client()
        self.col = self.db.collection(collection)

    def save(self, order: dict) -> None:
        self.col.document(order["order_id"]).set(order)

    def find_by_customer(self, customer_id: str) -> list:
        return [d.to_dict() for d in
                self.col.where("customer_id", "==", customer_id).stream()]

    def update_status(self, order_id: str, status: str) -> None:
        self.col.document(order_id).update({"status": status})
```

---

## Step 4 — Config Fix

```python
# app_config.py — 12-Factor compliant
import os

DATABASE_TABLE = os.environ["DATABASE_TABLE"]
AWS_REGION     = os.environ["AWS_REGION"]
SESSION_SECRET = os.environ["SESSION_SECRET"]
MAX_RETRIES    = int(os.environ.get("MAX_RETRIES", "3"))
# Credentials via IAM Role (AWS) or Workload Identity (GCP) — never in code
```

---

## Step 5 — Migration Cost to GCP

**Code changes:**
- Replace DynamoDBOrderRepository with FirestoreOrderRepository — one file, zero business logic changes
- Remove active_sessions dict — externalize to Redis or Memorystore

**Config changes:**
- Replace AWS env vars with GCP equivalents (GCP_PROJECT, Firestore collection name)
- Credentials via Workload Identity Federation

**Infrastructure changes:**
- Provision Firestore (GCP equivalent of DynamoDB)
- Deploy on GKE instead of EC2
- CI/CD pipeline pointing to GCP Artifact Registry