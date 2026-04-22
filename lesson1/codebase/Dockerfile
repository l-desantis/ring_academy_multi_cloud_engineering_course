FROM python:3.11-slim

WORKDIR /app
COPY . .

RUN pip install boto3

# Config baked into the image at build time
ENV AWS_REGION="us-east-1"
ENV DATABASE_TABLE="orders-prod"
ENV AWS_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
ENV AWS_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

CMD ["python", "main.py"]