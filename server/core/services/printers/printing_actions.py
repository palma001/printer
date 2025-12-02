from abc import ABC, abstractmethod
from typing import Any


class PrintersServiceActions(ABC):
    @abstractmethod
    def getPrinters(self) -> list[Any]:
        pass

    @abstractmethod
    def sendToPrint(self, file_path: str, printer_name: str):
        pass
