import 'dart:convert';

import 'package:intl/intl.dart';
import "package:printer_ui_win/constants/env.dart";
import "package:printer_ui_win/utils/string_extension.dart";
import 'package:qr/qr.dart';
import "package:windows_printer/windows_printer.dart";

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

(List<String>, QrImage?, String?) generateTicketText(dynamic data) {
  List<String> lines = [];
  var sep = "-" * 40;
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
  lines.add("FECHA:".expand("${data["date"] ?? ""}"));
  lines.add("HORA:".expand("${data["hour"] ?? ""}"));
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
  lines.add("Cant x P.Unit".expand("IMPORTE"));
  lines.add("Descripción");
  lines.add(sep);

  for (var prod in data["products"] ?? []) {
    var cantidad = double.parse("${prod["pivot"]?["amount"] ?? "0.0"}");
    var precio = double.parse("${prod["pivot"]?["price"] ?? "0.0"}");
    var subtotal = cantidad * precio;
    var tax = double.parse("${prod["pivot"]?["taxe"] ?? "0.0"}");

    lines.add(
      "${cantidad.toStringAsFixed(2)} x ${precio.toStringAsFixed(2)}".expand(
        subtotal.toStringAsFixed(2),
      ),
    );
    if (tax > 0.0 && data["billing"] != null) {
      lines.add("IVA ${tax}%");
    }

    lines.add(prod["name"]?.toString().toUpperCase() ?? "");
  }

  lines.add(sep);
  lines.add(
    "TOTAL:".expand(
      double.parse("${data['total'] ?? "0.0"}").toStringAsFixed(2),
    ),
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

WPReceiptBuilder generateTicketReceipt(dynamic data) {
  WPReceiptBuilder receiptBuilder = WPReceiptBuilder(
    wpPaperSize: EnvVariables.receiptPaperSize == "58"
        ? WPPaperSize.mm58
        : WPPaperSize.mm80,
  );

  Map<String, dynamic> company = data["company"] ?? {};
  Map<String, Map> fields = data["electronic_invoice"]?["fields"] ?? {};

  // Encabezado
  receiptBuilder.header(
    [
      "RAZON SOCIAL: ${company["name"]?.toString().toUpperCase()}",
      "${data["client"]?["name"] ?? ""}",
      "DIRECCION: ${company["address"] ?? ""}",
      "C.U.I.T.: ${company["document_number"] ?? ""}",
      "",
      if (data["billing"] != null) "IIBB: ${fields["income_brut"] ?? "----"}",
      if (data["billing"] != null)
        "INICIO ACT: ${fields["activity_start_date"] ?? "----"}",
      "",
    ].join("\n"),
  );
  receiptBuilder.separator();

  // Factura centrada
  if (data["billing"] != null && fields["voucher_type"] != null) {
    receiptBuilder.line(
      fields["voucher_type"]?["Desc"]?.toString().toUpperCase() ?? "",
    );
    receiptBuilder.line("Código: ${fields["voucher_type"]?["Id"] ?? ""}");
    receiptBuilder.separator();
  }
  // Datos de la factura
  receiptBuilder.line("NRO: ${data["code"] ?? ""}");
  receiptBuilder.line(
    "CLIENTE: ${data["client"]?["name"] ?? "CONSUMIDOR FINAL"}",
  );
  receiptBuilder.line("FECHA: ${data["date"] ?? ""}");
  receiptBuilder.line("HORA: ${data["hour"] ?? ""}");
  Map seller = data["seller"] ?? {};
  receiptBuilder.line("Vendedor: ${seller["name"] ?? ""}");
  receiptBuilder.line("TIPO: ${data["invoice_type"]?["name"] ?? ""}");
  if (data["billing"] != null) {
    receiptBuilder.line("CONCEPTO: ${fields["concept_type"]?["Desc"] ?? ""}");
  }
  if (data["tables"] != null) {
    for (var table in data["tables"]) {
      receiptBuilder.line(
        "MESA: ${table["name"] ?? ""} SALA ${table["living_room"]?["name"] ?? ""}",
      );
    }
  }
  receiptBuilder.separator();

  // Detalle
  receiptBuilder.item("Cant x P.Unit", "IMPORTE");
  receiptBuilder.line("Descripcion");
  receiptBuilder.separator();

  for (var prod in data["products"] ?? []) {
    var cantidad = double.parse("${prod["pivot"]?["amount"] ?? "0.0"}");
    var precio = double.parse("${prod["pivot"]?["price"] ?? "0.0"}");
    var subtotal = cantidad * precio;
    var tax = double.parse("${prod["pivot"]?["taxe"] ?? "0.0"}");

    receiptBuilder.item(
      "${cantidad.toStringAsFixed(2)} x ${precio.toStringAsFixed(2)}",
      "${subtotal.toStringAsFixed(2)}",
    );
    if (tax > 0.0 && data["billing"] != null) {
      receiptBuilder.line("IVA ${tax}%");
    }

    receiptBuilder.line(prod["name"]?.toString().toUpperCase() ?? "");
  }

  receiptBuilder.separator();
  receiptBuilder.totalAmt(
    "${double.parse("${data['total'] ?? "0.0"}").toStringAsFixed(2)}",
  );
  receiptBuilder.separator();

  // CAE y Vto
  if (data["billing"] != null && fields["cae"] != null) {
    receiptBuilder.line("CAE: ${fields["cae"] ?? ""}");
    receiptBuilder.line("Vto: ${fields["caef_ch_vto"] ?? ""}");
  }
  if (data["billing"] != null) {
    var (_, qrString) = generate_afip_qr(data, company, fields);
    receiptBuilder.addQRCode(qrString);
  }
  receiptBuilder.blank(3);
  receiptBuilder.cut(partial: false);
  return receiptBuilder;
}
