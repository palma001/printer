import re
import socket
from typing import Any

from core.constants.doc import TMP_DIR
from core.services.printers import PrintersService
from core.services.ticket import ReceiptType, generate_pdf_receipt
from core.state.app_state import AppStateObserver, AppStateType


async def print_ticket(
    destination: str, data: dict[str, Any], printer_size: int, doc_type: str
) -> None:
    """Prints a ticket to a local CUPS printer."""
    try:
        receipt_type = (
            ReceiptType.COMMAND
            if re.match("^comm", doc_type, re.IGNORECASE)
            else ReceiptType.RECEIPT
        )
        content_pdf = await generate_pdf_receipt(data, printer_size, receipt_type)

        AppStateObserver.add(
            AppStateType.PRINTING, message=f"Printing ticket to: {destination}"
        )
        with open(TMP_DIR / "receipt.pdf", "wb") as f:
            f.write(content_pdf)
            PrintersService().sendToPrint(
                str((TMP_DIR / "receipt.pdf").resolve()), destination
            )
            AppStateObserver.add(AppStateType.CONNECTED)

    except Exception as e:
        AppStateObserver.add(
            AppStateType.ERROR,
            message=f"Error sending ticket to printer at {destination}: {e}",
        )


async def print_network_ticket(
    destination: str, data: dict[str, Any], printer_size: int, doc_type: str
) -> None:
    """Prints a ticket to a network printer."""
    try:
        receipt_type = (
            ReceiptType.COMMAND
            if re.match("^comm", doc_type, re.IGNORECASE)
            else ReceiptType.RECEIPT
        )
        receipt_pdf = await generate_pdf_receipt(data, printer_size, receipt_type)
        AppStateObserver.add(
            AppStateType.PRINTING, message=f"Printing {receipt_type} to: {destination}"
        )
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5)
            s.connect((destination, 9100))
            s.sendall(receipt_pdf)
            AppStateObserver.add(AppStateType.CONNECTED)
    except Exception as e:
        AppStateObserver.add(
            AppStateType.ERROR,
            message=f"Error sending ticket to printer at {destination}: {e}",
        )


async def print_invoice(
    data: dict[str, Any], destination: str, doc_type: str, printer_size: int = 58
) -> None:
    """Determines whether to print to a local or network printer."""
    if re.match(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$", destination):
        await print_network_ticket(destination, data, printer_size, doc_type)
    else:
        await print_ticket(destination, data, printer_size, doc_type)
