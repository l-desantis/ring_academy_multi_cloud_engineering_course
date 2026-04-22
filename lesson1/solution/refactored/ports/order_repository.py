from abc import ABC, abstractmethod

class OrderRepository(ABC):

    @abstractmethod
    def save(self, order: dict) -> None: ...

    @abstractmethod
    def find_by_customer(self, customer_id: str) -> list: ...

    @abstractmethod
    def update_status(self, order_id: str, status: str) -> None: ...