from google.cloud import firestore
from ports.order_repository import OrderRepository

class FirestoreOrderRepository(OrderRepository):

    def __init__(self, collection: str):
        self.db = firestore.Client()
        self.col = self.db.collection(collection)

    def save(self, order: dict) -> None:
        self.col.document(order["order_id"]).set(order)

    def find_by_customer(self, customer_id: str) -> list:
        return [
            d.to_dict()
            for d in self.col.where("customer_id", "==", customer_id).stream()
        ]

    def update_status(self, order_id: str, status: str) -> None:
        self.col.document(order_id).update({"status": status})