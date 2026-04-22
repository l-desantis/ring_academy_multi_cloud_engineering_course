# Audit Worksheet — 12-Factor Compliance

## Step 1 — Factor Violations
For each violation found, fill in the table:

| Factor # | Factor Name | Violation Found | File / Line | Severity (High/Med/Low) |
|----------|-------------|-----------------|-------------|--------------------------|
|          |             |                 |             |                          |

## Step 2 — Lock-In Assessment
Which violations create **vendor lock-in** (not just bad practice)?
List each one and explain why migrating to GCP would be blocked by it.

## Step 3 — ACL Design
Pick ONE backing service from the codebase (DynamoDB).
Sketch the StoragePort interface that would decouple it:

```python
class OrderRepository:  # your interface here
    def save(self, order) -> None: ...
    def find_by_customer(self, customer_id) -> list: ...
    def update_status(self, order_id, status) -> None: ...
```

## Step 4 — Config Fix
Rewrite `app_config.py` to be 12-Factor compliant (Factor #3).

## Step 5 — Migration Cost Estimate
If the company decided to migrate this service to GCP **today**, 
what would need to change? Categorize as:
- Code changes
- Config changes  
- Infrastructure changes