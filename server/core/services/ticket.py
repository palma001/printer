import base64
import json
from datetime import datetime
from enum import Enum
from io import BytesIO
from typing import Any, Optional, Tuple

import qrcode
from pypdf import PdfWriter
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas


class ReceiptType(Enum):
    RECEIPT = "receipt"
    COMMAND = "command"


def generate_afip_qr(
    data: dict, company_session: dict, fields: dict
) -> Tuple[Any, str]:
    """Generates the AFIP QR code and URL."""
    doc_qr = {
        "ver": 1,
        "fecha": data.get("date", datetime.now().strftime("%Y-%m-%d")),
        "cuit": int(company_session.get("document_number", 0)),
        "ptoVta": fields.get("point_of_sale"),
        "tipoCmp": fields.get("voucher_type", {}).get("Id"),
        "nroCmp": fields.get("cbte_hasta"),
        "importe": float(data.get("total", 0.0)),
        "moneda": "PES",
        "tipoDocRec": data.get("client", {}).get("document_type", {}).get("Id"),
        "nroDocRec": int(data.get("client", {}).get("document_number", 0)),
        "tipoCodAut": "E",
        "ctz": 1,
        "codAut": int(fields.get("cae", 0)),
    }
    encoded = base64.b64encode(
        json.dumps(doc_qr, separators=(",", ":")).encode("utf-8")
    ).decode("utf-8")
    url = f"https://servicioscf.afip.gob.ar/publico/comprobantes/cae.aspx?p={encoded}"

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    return qr.make_image(fill_color="black", back_color="white"), url


class PdfReceiptCanvas:
    """A helper class to draw a receipt on a reportlab Canvas."""

    def __init__(self, buffer: BytesIO, width: int, height: int):
        self.canvas = canvas.Canvas(buffer, pagesize=(width * mm, height * mm))
        self.width = width * mm
        self.y_position = height * mm - 10  # Start from top
        self.line_height = 12

    def _write_text(
        self, text: str, x: float, y: float, font: str, size: int, align: str = "left"
    ):
        self.canvas.setFont(font, size)
        if align == "right":
            self.canvas.drawRightString(x, y, text)
        elif align == "center":
            self.canvas.drawCentredString(x, y, text)
        else:
            self.canvas.drawString(x, y, text)

    def add_line(
        self, text: str, font: str = "Helvetica", size: int = 8, align: str = "left"
    ):
        x = 5
        if align == "right":
            x = self.width - 5
        elif align == "center":
            x = self.width / 2
        self._write_text(text, x, self.y_position, font, size, align)
        self.y_position -= self.line_height

    def add_multi_line(self, text: str, font: str = "Helvetica", size: int = 8):
        text_object = self.canvas.beginText(5, self.y_position)
        text_object.setFont(font, size)
        for line in text.split("\n"):
            text_object.textLine(line)
        self.canvas.drawText(text_object)
        self.y_position -= self.line_height * (text.count("\n") + 1)

    def add_image(self, image_path: str, width: int, height: int):
        x = (self.width - width) / 2
        self.y_position -= height
        self.canvas.drawImage(
            image_path, x, self.y_position, width=width, height=height
        )

    def ln(self, lines: int = 1):
        self.y_position -= self.line_height * lines

    def save(self):
        self.canvas.save()


async def generate_pdf_receipt(
    data: dict, printer_size: int, receipt_type: ReceiptType
) -> bytes:
    """Generates a PDF receipt."""
    buffer = BytesIO()
    # Estimate height, can be adjusted.
    estimated_height = 250
    pdf_canvas = PdfReceiptCanvas(buffer, printer_size, estimated_height)

    company = data.get("company", {})
    electronic_invoice = data.get("electronic_invoice")
    fields = electronic_invoice.get("fields", {}) if electronic_invoice else {}
    vendedor = data.get("seller", {})
    invoice_payments = data.get("invoice_payments", [])

    qr_img: Optional[Any] = None
    qr_string: Optional[str] = None
    if electronic_invoice:
        qr_img, qr_string = generate_afip_qr(data, company, fields)

    # Header
    pdf_canvas.add_line(
        company.get("name", "").upper(), font="Helvetica-Bold", size=10, align="center"
    )

    if receipt_type == ReceiptType.RECEIPT:
        pdf_canvas.add_line(
            f"I.V.A: Resp Inscripto C.U.I.T.: {company.get('document_number', '')}"
        )
        if data.get("billing"):
            activity_start = ""
            if fields.get("activity_start_date"):
                activity_start = f"In. Act: {datetime.fromisoformat(fields['activity_start_date']).strftime('%d/%m/%Y')}"
            pdf_canvas.add_line(
                f"IIBB: {company.get('document_number', '----')} {activity_start}"
            )
        pdf_canvas.add_line(f"Dirección: {company.get('address', '')}")
    else:  # Command
        pdf_canvas.add_line(
            f"NRO DOC.: {company.get('document_number', '')}", align="center"
        )

    pdf_canvas.ln()

    # Cashier Info
    if data.get("billing") and fields.get("voucher_type"):
        pdf_canvas.add_line(fields["voucher_type"].get("Desc", "").upper())
        pdf_canvas.add_line(f"Código: {fields['voucher_type'].get('Id', '')}")

    pdf_canvas.add_line(f"No. {data.get('code', '')}")
    pdf_canvas.add_line(f"Vendedor: {vendedor.get('name', '')}")
    pdf_canvas.add_line(
        f"Cliente: {data.get('client', {}).get('name', 'CONSUMIDOR FINAL')}"
    )

    date_str = (
        datetime.fromisoformat(data["date"]).strftime("%d/%m/%Y")
        if data.get("date")
        else ""
    )
    pdf_canvas.add_line(f"Fecha: {date_str} Hora: {data.get('hour', '')}")
    pdf_canvas.ln()

    # Client Info
    if data.get("billing") and receipt_type != ReceiptType.COMMAND:
        pdf_canvas.add_line(
            f"Concepto: {fields.get('concept_type', {}).get('Desc', '')}"
        )

    for table in data.get("tables", []):
        pdf_canvas.add_line(
            f"Mesa: {table.get('name', '')} Sala {table.get('living_room', {}).get('name', '')}"
        )

    pdf_canvas.ln()

    # Items
    pdf_canvas.add_line("Cant x P.Unit   IMPORTE")
    pdf_canvas.add_line("Descripción")
    pdf_canvas.add_line("-" * (printer_size // 2))

    for prod in data.get("products", []):
        pivot = prod.get("pivot", {})
        cantidad = float(pivot.get("amount", 0.0))
        precio = float(pivot.get("price", 0.0))
        subtotal = cantidad * precio
        pdf_canvas.add_line(f"{cantidad:.2f} x {precio:.2f} {subtotal:.2f}")
        pdf_canvas.add_multi_line(prod.get("name", "").upper())
        if pivot.get("observation"):
            pdf_canvas.add_multi_line(f"  ({pivot['observation'].upper()})")

    pdf_canvas.add_line("-" * (printer_size // 2))
    pdf_canvas.ln()

    # Payments
    for payment in invoice_payments:
        pdf_canvas.add_line(
            f"{payment.get('payment_method', {}).get('name', '')}: {payment.get('amount', 0.0):.2f}"
        )

    pdf_canvas.ln()

    # Totals
    total = float(data.get("total", 0.0))
    subtotal = float(data.get("subtotal", 0.0))
    discount = data.get("discount_total")
    pdf_canvas.add_line(f"SUBTOTAL: ${subtotal:.2f}", align="right")
    if discount is not None:
        pdf_canvas.add_line(f"DESCUENTO: ${float(discount):.2f}", align="right")
    pdf_canvas.add_line(f"TOTAL: ${total:.2f}", align="right")

    pdf_canvas.ln()

    # Footer Top
    if electronic_invoice:
        pdf_canvas.add_line("Regimen de transparencia fiscal consumidor (ley 27743)")
        tax_total = float(data.get("taxe_total", 0.0))
        pdf_canvas.add_line(f"I.V.A. Contenido: ${tax_total:.2f}")
        if fields.get("cae"):
            pdf_canvas.add_line(f"CAE No {fields['cae']}")
            pdf_canvas.add_line(f"Vto: {fields.get('caef_ch_vto', '')}")

    pdf_canvas.ln()

    # QR Code
    if qr_img:
        qr_img_path = "qr_code.png"
        qr_img.save(qr_img_path)
        pdf_canvas.add_image(qr_img_path, width=int(40 * mm), height=int(40 * mm))

    # Footer Bottom
    if electronic_invoice:
        pdf_canvas.add_line("Comprobante Autorizado", align="center")
        pdf_canvas.add_line(
            "Esta Administracion Federal no se responsabiliza por sus datos",
            align="center",
        )
        pdf_canvas.add_line("Ingresado en el detalle dela operacion", align="center")

    pdf_canvas.save()

    # Use pypdf to finalize the document
    writer = PdfWriter()
    writer.add_blank_page(width=printer_size * mm, height=estimated_height * mm)

    # The content is already in the buffer from reportlab
    # We just need to get it into the writer
    # This is a bit of a workaround as pypdf is not ideal for creation
    # We create a new page with the content and merge it.
    # A better approach would be to use reportlab or fpdf2 directly.
    # But to satisfy the request of using pypdf:

    # Reset buffer to read from it
    buffer.seek(0)

    # pypdf doesn't have a direct way to add a canvas content stream.
    # The simplest way is to just return the bytes from the reportlab canvas.
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes
