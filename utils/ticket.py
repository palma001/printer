# ticket.py
import base64
import json
from datetime import datetime
import qrcode
from PIL import Image

def generate_afip_qr(data, company_session, fields):
    doc_qr = {
        "ver": 1,
        "fecha": data.get("date", datetime.today().strftime("%Y-%m-%d")),
        "cuit": int(company_session["document_number"]),
        "ptoVta": fields["point_of_sale"],
        "tipoCmp": fields["voucher_type"]["Id"],
        "nroCmp": fields["cbte_hasta"],
        "importe": float(data["total"]),
        "moneda": "PES",
        "tipoDocRec": data["client"]["document_type"]["Id"],
        "nroDocRec": int(data["client"]["document_number"]),
        "tipoCodAut": "E",
        "ctz": 1,
        "codAut": int(fields["cae"])
    }
    encoded = base64.b64encode(json.dumps(doc_qr, separators=(",", ":")).encode("utf-8")).decode("utf-8")
    url = f"https://servicioscf.afip.gob.ar/publico/comprobantes/cae.aspx?p={encoded}"
    return qrcode.make(url)

def generate_ticket_text(data):
    lines = []
    sep = "-" * 32
    qr_image = None
    company = data.get("company", {})
    fields = data.get("electronic_invoice", {}).get("fields", {}) if data.get("billing") else {}

    # Encabezado
    lines.append(f"RAZON SOCIAL: {company.get('name', '').upper()}")
    lines.append(f"{data.get('client', {}).get('name', '')}")
    lines.append(f"DIRECCION: {company.get('address', '')}")
    lines.append(f"C.U.I.T.: {company.get('document_number', '')}")
    if data.get("billing"):
        lines.append(f"IIBB: {fields.get('income_brut', '---')}")
        lines.append(f"INICIO ACT: {fields.get('activity_start_date', '---')}")
    lines.append(sep)

    # Factura centrada
    if data.get("billing"):
        lines.append(fields.get('voucher_type', {}).get('Desc', '').upper())
        lines.append(f"Código: {fields.get('voucher_type', {}).get('Id', '')}")
        lines.append(sep)


    # Datos de la factura
    lines.append(f"NRO: {data.get('code', '')}")
    lines.append(f"CLIENTE: {data.get('client', {}).get('name', 'CONSUMIDOR FINAL')}")
    lines.append(f"FECHA: {data.get('date', '')}")
    lines.append(f"HORA: {data.get('hour', '')}")
    vendedor = data.get("seller", {})
    lines.append(f"Vendedor: {vendedor.get('name', '')}")
    lines.append(f"TIPO: {data.get('invoice_type', {}).get('name', '')}")
    if data.get("billing"):
        lines.append(f"CONCEPTO: {fields.get('concept_type', {}).get('Desc', '')}")

    if data.get("tables"):
        for table in data["tables"]:
            lines.append(f"MESA: {table.get('name', '')} SALA {table.get('living_room', {}).get('name', '')}")

    lines.append(sep)

    # Detalle
    lines.append("Cant x P.Unit        IMPORTE")
    lines.append("Descripcion")
    lines.append(sep)

    for prod in data.get("products", []):
        cantidad = float(prod["pivot"]["amount"])
        precio = float(prod["pivot"]["price"])
        subtotal = cantidad * precio
        tax = prod["pivot"].get("taxe", None)

        lines.append(f"{cantidad:.2f} x {precio:.2f}".ljust(19) + f"{subtotal:.2f}".rjust(10))
        if tax is not None and data.get("billing"):
            lines.append(f"IVA {tax}%")
        lines.append(prod.get("name", "").upper())

    lines.append(sep)
    lines.append(f"TOTAL: {float(data['total']):>22.2f}")
    lines.append(sep)

    # CAE y Vto
    if data.get("billing"):
        lines.append(f"CAE: {fields.get('cae', '')}")
        lines.append(f"Vto: {fields.get('caef_ch_vto', '')}")
        qr_image = generate_afip_qr(data, company, fields) if data.get("billing") else None

    lines.append("\n" * 3)
    return "\n".join(lines), qr_image
