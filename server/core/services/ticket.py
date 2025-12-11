import base64
import io
import json
from datetime import datetime
from enum import Enum
from typing import Any

import pdfkit
import qrcode
from jinja2 import Environment, FileSystemLoader

from core.constants import IMG_DIR, TEMPLATE_DIR, TMP_DIR


class ReceiptType(Enum):
    RECEIPT = "receipt"
    COMMAND = "command"


def generate_afip_qr(
    data: dict[str, Any],
    company_session: dict[str, Any] = {},
    fields: dict[str, Any] = {},
):
    """Generates the AFIP QR code and URL."""
    doc_qr = {
        "ver": 1,
        "fecha": data.get("date", datetime.now().strftime("%Y-%m-%d")),
        "cuit": int(company_session.get("document_number", "0"))
        if company_session.get("document_number", "0") is not None
        else "",
        "ptoVta": fields.get("point_of_sale", ""),
        "tipoCmp": fields.get("voucher_type", {}).get("id", ""),
        "nroCmp": fields.get("cbte_hasta", ""),
        "importe": float(data.get("total", 0.0)),
        "moneda": "PES",
        "tipoDocRec": data["client"]["document_type"]["id"]
        if data["client"]["document_type"] is not None
        else "0",
        "nroDocRec": int(data.get("client", {}).get("document_number", "0"))
        if data.get("client", {}).get("document_number", "0") is not None
        else "",
        "tipoCodAut": "E",
        "ctz": 1,
        "codAut": int(fields.get("cae", 0)) if fields.get("cae", 0) is not None else "",
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


class PdfReceiptPDF:
    def __init__(
        self,
        type: ReceiptType = ReceiptType.RECEIPT,
        data: dict[str, Any] = {},
        printer_size: int = 58,
        qr_code: str | None = None,
        tax_img: str | None = None,
    ):
        self.type = type
        self.data = data
        self.printer_size = printer_size
        self.qr_code = qr_code
        self.tax_img = tax_img
        self.template = Environment(
            loader=FileSystemLoader(TEMPLATE_DIR.resolve())
        ).get_template(f"{type.value}.html")

    def _render(self) -> str:
        return self.template.render(
            data=self.data,
            printer_size=self.printer_size,
            qr_code=self.qr_code,
            tax_img=self.tax_img,
        )

    def save(self) -> str:
        pdfkit.from_string(self._render(), f"{TMP_DIR}/{self.type.value}.pdf")
        return f"{TMP_DIR}/{self.type.value}.pdf"


async def generate_pdf_receipt(
    data: dict[str, Any], printer_size: int, type: ReceiptType
) -> str:
    with open(IMG_DIR / "arca.png", "rb") as tax_img_file:
        tax_img_data = tax_img_file.read()
        tax_img_b64 = base64.b64encode(tax_img_data).decode("utf-8")
    qr_img_raw = generate_afip_qr(
        data=data,
        company_session=data["company"],
        fields=data["electronic_invoice"]["fields"]
        if data["electronic_invoice"] is not None
        else {},
    )[0]
    qr_img_buffer = io.BytesIO()
    qr_img_raw.save(qr_img_buffer, format="PNG")
    qr_code_b64 = base64.b64encode(qr_img_buffer.getvalue()).decode("utf-8")
    return PdfReceiptPDF(
        type=type,
        data=data,
        printer_size=printer_size,
        qr_code=f"data:image/png;base64,{qr_code_b64}",
        tax_img=f"data:image/png;base64,{tax_img_b64}",
    ).save()
