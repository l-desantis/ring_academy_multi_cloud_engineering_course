# logger.py

import logging

logging.basicConfig(
    filename="/var/log/orderservice/app.log",
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger("order_service")