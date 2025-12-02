from core.services.printers.printing_actions import PrintersServiceActions


class LinuxPrintersService(PrintersServiceActions):
    def getPrinters(self):
        import cups

        conn = cups.Connection()
        printers = conn.getPrinters()
        return [printer for printer in printers]

    def sendToPrint(self, file_path: str, printer_name: str):
        import cups

        conn = cups.Connection()
        if printer_name not in conn.getPrinters():
            raise ValueError(f"Printer {printer_name} not found")
        conn.printFile(printer_name, file_path, "Print Job", {})
