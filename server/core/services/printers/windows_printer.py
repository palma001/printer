from typing import Any

from core.services.printers.printing_actions import PrintersServiceActions


class WindowsPrintersService(PrintersServiceActions):
    def getPrinters(self) -> list[Any]:
        import win32print

        printers = win32print.EnumPrinters(win32print.PRINTER_ENUM_LOCAL, None, 1)
        return [name for flag, description, name, comment in printers]

    def sendToPrint(self, file_path: str, printer_name: str):
        """print pdf file to printer on windows using win32print"""
        import win32print

        printer_handle = win32print.OpenPrinter(printer_name)
        win32print.StartDocPrinter(printer_handle, 1, (printer_name, "RAW", None))
        win32print.StartPagePrinter(printer_handle)
        with open(file_path, "rb") as f:
            win32print.WritePrinter(printer_handle, f.read())
        win32print.EndPagePrinter(printer_handle)
        win32print.EndDocPrinter(printer_handle)
        win32print.ClosePrinter(printer_handle)
