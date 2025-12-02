import platform

from core.services.printers.linux_printer import LinuxPrintersService
from core.services.printers.printing_actions import PrintersServiceActions
from core.services.printers.windows_printer import WindowsPrintersService


class PrintersService:
    @property
    def _platform(self) -> str:
        return platform.system()

    _registry: dict[str, PrintersServiceActions] = {
        "Windows": WindowsPrintersService(),
        "Linux": LinuxPrintersService(),
    }

    def getPrinters(self):
        return self._registry[self._platform].getPrinters()

    def sendToPrint(self, file_path: str, printer_name: str):
        return self._registry[self._platform].sendToPrint(
            file_path=file_path, printer_name=printer_name
        )
