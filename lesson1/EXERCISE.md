# Is This App Cloud-Native or Cloud-Hosted?
## A 12-Factor Audit — Practical Exercise

### Context
You have just inherited the order service from a mid-size e-commerce platform.
The previous team containerized it six months ago and called it "cloud-native."

Your task: verify that claim using the 12-Factor checklist and identify exactly 
where the architecture creates vendor lock-in — before the company commits to 
a multi-cloud strategy.

### The service handles:
- Saving a new order to the database
- Reading a customer's order history
- Updating an order's status

### Stack
Python + boto3 (AWS SDK) + DynamoDB + Docker

### Instructions
1. Read all files in `/codebase/` carefully
2. Open `WORKSHEET.md`
3. Work through the five steps — there are **at least 6 Factor violations** to find
4. Some violations are not obvious at first read — look beyond the first `import`