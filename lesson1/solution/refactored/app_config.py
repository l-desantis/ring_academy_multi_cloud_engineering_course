# app_config.py — 12-Factor compliant
import os

DATABASE_TABLE = os.environ["DATABASE_TABLE"]
AWS_REGION     = os.environ["AWS_REGION"]
SESSION_SECRET = os.environ["SESSION_SECRET"]
MAX_RETRIES    = int(os.environ.get("MAX_RETRIES", "3"))