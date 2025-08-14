import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:qr/qr.dart';

(QrImage, String) generate_afip_qr(
  dynamic data,
  dynamic company_session,
  dynamic fields,
) {
  var doc_qr = {
    "ver": 1,
    "fecha": data["date"] ?? DateFormat("yyyy-MM-dd").format(DateTime.now()),
    "cuit": int.parse("${company_session["document_number"] ?? "0"}"),
    "ptoVta": fields["point_of_sale"],
    "tipoCmp": fields["voucher_type"]?["Id"] ?? "",
    "nroCmp": fields["cbte_hasta"],
    "importe": double.parse("${data["total"] ?? "0.0"}"),
    "moneda": "PES",
    "tipoDocRec": data["client"]?["document_type"]?["Id"] ?? "",
    "nroDocRec": int.parse("${data["client"]?["document_number"] ?? "0"}"),
    "tipoCodAut": "E",
    "ctz": 1,
    "codAut": int.parse("${fields["cae"] ?? "0"}"),
  };
  var encoded = base64.encode(
    utf8.encode(json.encode(doc_qr).replaceAll(" ", "").replaceAll("\n", "")),
  );
  var url =
      "https://servicioscf.afip.gob.ar/publico/comprobantes/cae.aspx?p=$encoded";
  return (QrImage(QrCode(40, QrErrorCorrectLevel.L)..addData(url)), url);
}

(List<String>, QrImage, String) generateTicketText(dynamic data) {
  List<String> lines = [];
  var sep = "-" * 20;
  var qr_image = null;
  var qr_string = null;
  Map<String, dynamic> company = data["company"] ?? {};
  Map<String, Map> fields = data["electronic_invoice"]?["fields"] ?? {};

  // Encabezado
  lines.add("RAZON SOCIAL: ${company["name"]?.toString().toUpperCase()}");
  lines.add("${data["client"]?["name"] ?? ""}");
  lines.add("DIRECCION: ${company["address"] ?? ""}");
  lines.add("C.U.I.T.: ${company["document_number"] ?? ""}");
  if (data["billing"] != null) {
    lines.add("IIBB: ${fields["income_brut"] ?? "----"}");
    lines.add("INICIO ACT: ${fields["activity_start_date"] ?? "----"}");
  }
  lines.add(sep);
  // Factura centrada
  if (data["billing"] != null && fields["voucher_type"] != null) {
    lines.add(fields["voucher_type"]?["Desc"]?.toString().toUpperCase() ?? "");
    lines.add("Código: ${fields["voucher_type"]?["Id"] ?? ""}");
    lines.add(sep);
  }
  // Datos de la factura
  lines.add("NRO: ${data["code"] ?? ""}");
  lines.add("CLIENTE: ${data["client"]?["name"] ?? "CONSUMIDOR FINAL"}");
  lines.add("FECHA: ${data["date"] ?? ""}");
  lines.add("HORA: ${data["hour"] ?? ""}");
  lines.add("HORA: ${data["hour"] ?? ""}");
  Map vendedor = data["seller"] ?? {};
  lines.add("Vendedor: ${vendedor["name"] ?? ""}");
  lines.add("TIPO: ${data["invoice_type"]?["name"] ?? ""}");
  if (data["billing"] != null) {
    lines.add("CONCEPTO: ${fields["concept_type"]?["Desc"] ?? ""}");
  }
  if (data["tables"] != null) {
    for (var table in data["tables"]) {
      lines.add(
        "MESA: ${table["name"] ?? ""} SALA ${table["living_room"]?["name"] ?? ""}",
      );
    }
  }

  lines.add(sep);

  // Detalle
  lines.add("Cant x P.Unit  |  IMPORTE");
  lines.add("Descripcion");
  lines.add(sep);

  for (var prod in data["products"] ?? []) {
    var cantidad = double.parse("${prod["pivot"]?["amount"] ?? "0.0"}");
    var precio = double.parse("${prod["pivot"]?["price"] ?? "0.0"}");
    var subtotal = cantidad * precio;
    var tax = double.parse("${prod["pivot"]?["taxe"] ?? "0.0"}");

    lines.add(
      "${cantidad.toStringAsFixed(2)} x ${precio.toStringAsFixed(2)}"
      "  |  "
      "${subtotal.toStringAsFixed(2)}",
    );
    if (tax != null && data["billing"] != null) {
      lines.add("IVA ${tax}%");
    }

    lines.add(prod["name"]?.toString().toUpperCase() ?? "");
  }

  lines.add(sep);
  lines.add(
    "TOTAL: ${double.parse("${data['total'] ?? "0.0"}").toStringAsFixed(2)}",
  );
  lines.add(sep);

  // CAE y Vto
  if (data["billing"] != null && fields["cae"] != null) {
    lines.add("CAE: ${fields["cae"] ?? ""}");
    lines.add("Vto: ${fields["caef_ch_vto"] ?? ""}");
    if (data["billing"] != null) {
      (qr_image, qr_string) = generate_afip_qr(data, company, fields);
    }
  }

  lines.add("\n" * 3);
  return (lines, qr_image, qr_string);
}
