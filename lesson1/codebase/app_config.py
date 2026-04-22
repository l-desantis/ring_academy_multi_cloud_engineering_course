# app_config.py — loaded at startup

DATABASE_ENDPOINT = "dynamodb.us-east-1.amazonaws.com"
DATABASE_TABLE    = "orders-prod"
AWS_ACCESS_KEY    = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_KEY    = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
AWS_REGION        = "us-east-1"

LOG_FILE_PATH     = "/var/log/orderservice/app.log"
SESSION_SECRET    = "hardcoded-secret-do-not-share"

MAX_RETRIES = 3