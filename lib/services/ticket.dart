import "dart:convert";

import "package:date_format/date_format.dart";
import "package:flutter/foundation.dart";
import "package:intl/intl.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pdfw;
import "package:qbitsinc_printer_manager/utils/receipt_pdf_builder.dart";
import "package:qbitsinc_printer_manager/utils/receipt_txt_builder.dart";
import "package:qbitsinc_printer_manager/utils/string_extension.dart";
import "package:qr/qr.dart";

(QrImage, String) generate_afip_qr(
  dynamic data,
  dynamic companySession,
  dynamic fields,
) {
  var docQr = {
    "ver": 1,
    "fecha": data["date"] ?? DateFormat("yyyy-MM-dd").format(DateTime.now()),
    "cuit": int.parse("${companySession["document_number"] ?? "0"}"),
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
    utf8.encode(json.encode(docQr).replaceAll(" ", "").replaceAll("\n", "")),
  );
  var url =
      "https://servicioscf.afip.gob.ar/publico/comprobantes/cae.aspx?p=$encoded";
  return (QrImage(QrCode(40, QrErrorCorrectLevel.L)..addData(url)), url);
}

Future<Uint8List> generatePDFReceipt(
  dynamic data,
  int printerSize,
  ReceiptType type,
) {
  ReceiptPDFBuilder builder = ReceiptPDFBuilder();
  Map<String, dynamic> company = data["company"] ?? {};
  Map<String, dynamic>? electronicInvoice = data["electronic_invoice"];
  Map<String, dynamic> fields = data["electronic_invoice"]?["fields"] ?? {};
  Map<String, dynamic> vendedor = data["seller"] ?? {};
  List<dynamic> invoicePayments = data["invoice_payments"] ?? [];
  var (_, qrString) = generate_afip_qr(data, company, fields);
  builder
      .addInHeader(
        type == ReceiptType.command
            ? [
                ReceiptPDFBuilder.Line(
                  left: "${company["name"]?.toString().toUpperCase()}  ",
                  right: "NRO DOC.: ${company["document_number"] ?? ""}",
                  align: pdfw.WrapAlignment.center,
                ),
              ]
            : [
                ReceiptPDFBuilder.Line(
                  left: "${company["name"]?.toString().toUpperCase()}",
                  align: pdfw.WrapAlignment.center,
                ),
                ReceiptPDFBuilder.Line(
                  left: "${data["client"]?["name"] ?? ""}",
                  align: pdfw.WrapAlignment.start,
                ),
                ReceiptPDFBuilder.Line(
                  left: "I.V.A: Resp Inscripto",
                  right: "C.U.I.T.: ${company["document_number"] ?? ""}",
                  align: pdfw.WrapAlignment.spaceBetween,
                  runAlignment: pdfw.WrapAlignment.center,
                ),
                ...(data["billing"] != null
                    ? [
                        ReceiptPDFBuilder.Line(
                          left: "IIBB: ${company["document_number"] ?? "----"}",
                          right: fields["activity_start_date"] != null
                              ? "In. Act: ${formatDate(DateTime.parse(fields["activity_start_date"]), [dd, "/", mm, "/", yyyy])}"
                              : "",
                          align: pdfw.WrapAlignment.spaceBetween,
                          runAlignment: pdfw.WrapAlignment.center,
                        ),
                      ]
                    : []),
                ReceiptPDFBuilder.Line(
                  left: "Dirección: ${company["address"] ?? ""}",
                  align: pdfw.WrapAlignment.start,
                  runAlignment: pdfw.WrapAlignment.center,
                ),
              ],
        headerImgUrl: company["url"],
      )
      .addInCashierInfo(
        [
          ?type == ReceiptType.receipt
              ? null
              : ReceiptPDFBuilder.Line(
                  left: "",
                  align: pdfw.WrapAlignment.start,
                  runAlignment: pdfw.WrapAlignment.start,
                  style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                ),
          ...(data["billing"] != null && fields["voucher_type"] != null
              ? [
                  ReceiptPDFBuilder.Line(
                    left:
                        fields["voucher_type"]?["Desc"]
                            ?.toString()
                            .toUpperCase() ??
                        "",
                    align: pdfw.WrapAlignment.start,
                    runAlignment: pdfw.WrapAlignment.center,
                  ),
                  ReceiptPDFBuilder.Line(
                    left: "Código: ${fields["voucher_type"]?["Id"] ?? ""}",
                    align: pdfw.WrapAlignment.start,
                    runAlignment: pdfw.WrapAlignment.center,
                  ),
                ]
              : []),
          ReceiptPDFBuilder.Line(
            left: "No. ${data["code"] ?? ""}",
            right: "Vendedor:  ${vendedor["name"] ?? ""}",
            align: pdfw.WrapAlignment.spaceBetween,
            style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
          ),
          ReceiptPDFBuilder.Line(
            left: "Cliente:  ${data["client"]?["name"] ?? "CONSUMIDOR FINAL"}",
            align: pdfw.WrapAlignment.spaceBetween,
            style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
          ),
          ReceiptPDFBuilder.Line(
            left:
                "Fecha: ${formatDate(DateTime.parse(data["date"]), [dd, "/", mm, "/", yyyy])}",
            right: "Hora:${data["hour"] ?? ""}",
            align: pdfw.WrapAlignment.spaceBetween,
            style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
          ),
        ],
        cod: type == ReceiptType.command
            ? null
            : fields["voucher_type"]?["id"] ??
                  "${data["invoice_type"]?["id"] ?? ""}",
        desc: type == ReceiptType.command
            ? null
            : (fields["voucher_type"]?["Desc"] as String?)?.split(" ")[0] ??
                  "${data["invoice_type"]?["name"] ?? ""}",
        type: type == ReceiptType.command
            ? null
            : (fields["voucher_type"]?["Desc"] as String?)?.split(" ")[1] ??
                  "${data["invoice_type"]?["acronym_serie"] ?? ""}",
      )
      .addInClientInfo([
        ...(data["billing"] != null && type != ReceiptType.command
            ? [
                ReceiptPDFBuilder.Line(
                  left: "Concepto: ${fields["concept_type"]?["Desc"] ?? ""}",
                ),
              ]
            : []),
        ...((data["tables"] as List<dynamic> ?? []).map(
          (table) => ReceiptPDFBuilder.Line(
            left:
                "Mesa: ${table["name"] ?? ""} Sala ${table["living_room"]?["name"] ?? ""}",
          ),
        )),
        ?type == ReceiptType.command
            ? null
            : ReceiptPDFBuilder.Line(
                left: "Direction: ${company["address"] ?? ""}",
                align: pdfw.WrapAlignment.start,
              ),
      ])
      .addItems(
        (data["products"] as List<dynamic>? ?? []).map((prod) {
          var cantidad = double.parse("${prod["pivot"]?["amount"] ?? "0.0"}");
          var precio = double.parse("${prod["pivot"]?["price"] ?? "0.0"}");
          var subtotal = cantidad * precio;
          return ReceiptPDFBuilder.Item(
            description: prod["name"]?.toString().toUpperCase() ?? "",
            units: double.parse("${prod["pivot"]?["amount"] ?? "0.0"}"),
            unitPrice: double.parse("${prod["pivot"]?["price"] ?? "0.0"}"),
            total: subtotal,
          );
        }).toList(),
      )
      .addPayments(
        invoicePayments
            .map(
              (payment) => ReceiptPDFBuilder.Payment(
                name: "${payment["payment_method"]?["name"] ?? ""}",
                amount: double.parse("${payment["amount"] ?? 0.0}"),
                discountAmount: payment["discount_amount"],
                discountPercentage: payment["discount_percentage"],
                coinName: payment["coin"]["name"],
                coinSymbol: payment["coin"]["symbol"],
              ),
            )
            .toList(),
      )
      .addTotal(
        total: double.parse("${data['total'] ?? "0.0"}"),
        totalNoDiscount: double.parse("${data['subtotal'] ?? "0.0"}"),
        totalDiscount: data["discount_total"] != null
            ? double.parse("${data["discount_total"]}")
            : null,
      )
      .addInFooterTop([
        ?electronicInvoice == null
            ? null
            : ReceiptPDFBuilder.Line(
                left: "Regimen de transparencia fiscal consumidor (ley 27743)",
                style: pdfw.TextStyle(fontStyle: pdfw.FontStyle.italic),
              ),
        ?electronicInvoice == null
            ? null
            : ReceiptPDFBuilder.Line(
                left: "I.V.A. Contenido",
                right:
                    "\$${double.parse("${data["taxe_total"] ?? "0.0"}").toStringAsFixed(2)}",
                align: pdfw.WrapAlignment.spaceEvenly,
              ),
        ...(data["billing"] != null && fields["cae"] != null
            ? [
                ReceiptPDFBuilder.Line(left: "CAE No ${fields["cae"] ?? ""}"),
                ReceiptPDFBuilder.Line(
                  left: "Vto: ${fields["caef_ch_vto"] ?? ""}",
                ),
              ]
            : []),
      ])
      .addInFooterBottom(
        electronicInvoice == null
            ? []
            : [
                ReceiptPDFBuilder.Line(
                  left: "Comprobante Autorizado",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontStyle: pdfw.FontStyle.italic,
                  ),
                ),
                ReceiptPDFBuilder.Line(
                  left:
                      "Esta Administracion Federal no se responsabiliza por sus datos",
                  style: pdfw.TextStyle(fontStyle: pdfw.FontStyle.italic),
                ),
                ReceiptPDFBuilder.Line(
                  left: "Ingresado en el detalle dela operacion",
                  style: pdfw.TextStyle(fontStyle: pdfw.FontStyle.italic),
                ),
              ],
      );

  return builder.build(
    pageFormat: PdfPageFormat(
      printerSize * PdfPageFormat.mm,
      double.infinity,
      marginAll: 2 * PdfPageFormat.cm,
    ),
    type: type,
    qrCodeData: electronicInvoice == null ? null : qrString,
  );
}

@deprecated
(String, QrImage?, String?) generateTicketText(dynamic data, int printerSize) {
  QrImage? qrImage;
  String? qrString;
  final ReceiptTxtBuilder receiptBuilder = ReceiptTxtBuilder(
    linesLength: printerSize - 26,
  );
  Map<String, dynamic> company = data["company"] ?? {};
  Map<String, Map> fields = data["electronic_invoice"]?["fields"] ?? {};

  // Encabezado
  receiptBuilder.addHeaderLines([
    "RAZON SOCIAL: ${company["name"]?.toString().toUpperCase()}",
    "${data["client"]?["name"] ?? ""}",
    "DIRECCION: ${company["address"] ?? ""}",
    "C.U.I.T.: ${company["document_number"] ?? ""}",
    ...(data["billing"] != null
        ? [
            "IIBB: ${fields["income_brut"] ?? "----"}",
            "INICIO ACT: ${fields["activity_start_date"] ?? "----"}",
          ]
        : []),
  ]).addSep();
  // Factura centrada
  if (data["billing"] != null && fields["voucher_type"] != null) {
    receiptBuilder.addLines([
      fields["voucher_type"]?["Desc"]?.toString().toUpperCase() ?? "",
      "Código: ${fields["voucher_type"]?["Id"] ?? ""}",
    ]).addSep();
  }
  // Datos de la factura
  Map vendedor = data["seller"] ?? {};
  receiptBuilder.addLines([
    "NRO: ${data["code"] ?? ""}",
    "CLIENTE: ${data["client"]?["name"] ?? "CONSUMIDOR FINAL"}",
    "FECHA:".expand("${data["date"] ?? ""}", printerSize - 26),
    "HORA:".expand("${data["hour"] ?? ""}", printerSize - 26),
    "Vendedor: ${vendedor["name"] ?? ""}",
    "TIPO: ${data["invoice_type"]?["name"] ?? ""}",
    ...((data["billing"] != null)
        ? ["CONCEPTO: ${fields["concept_type"]?["Desc"] ?? ""}"]
        : []),
    ...((data["tables"] != null)
        ? data["tables"].map((table) {
            return "MESA: ${table["name"] ?? ""} SALA ${table["living_room"]?["name"] ?? ""}";
          })
        : []),
  ]).addSep();

  // Detalle
  receiptBuilder.addItem("Cant x P.Unit", "IMPORTE");
  receiptBuilder.addLines(["Descripción"]).addSep();

  for (var prod in data["products"] ?? []) {
    var cantidad = double.parse("${prod["pivot"]?["amount"] ?? "0.0"}");
    var precio = double.parse("${prod["pivot"]?["price"] ?? "0.0"}");
    var subtotal = cantidad * precio;
    var tax = double.parse("${prod["pivot"]?["taxe"] ?? "0.0"}");

    receiptBuilder.addItem(
      "${cantidad.toStringAsFixed(2)} x ${precio.toStringAsFixed(2)}",
      subtotal.toStringAsFixed(2),
    );
    if (tax > 0.0 && data["billing"] != null) {
      receiptBuilder.addLines(["IVA $tax%"]);
    }

    receiptBuilder.addLines([prod["name"]?.toString().toUpperCase() ?? ""]);
  }

  receiptBuilder.addSep();
  receiptBuilder
      .addItem(
        "TOTAL:",
        double.parse("${data['total'] ?? "0.0"}").toStringAsFixed(2),
      )
      .addSep()
      .addLines([
        // CAE y Vto
        ...(data["billing"] != null && fields["cae"] != null)
            ? [
                "CAE: ${fields["cae"] ?? ""}",
                "Vto: ${fields["caef_ch_vto"] ?? ""}",
                ...((data["billing"] != null) ? [] : []),
              ]
            : [],
      ])
      .addLines(["\n" * 3]);

  if (data["billing"] != null) {
    (qrImage, qrString) = generate_afip_qr(data, company, fields);
  }

  return (receiptBuilder.build(), qrImage, qrString);
}

@deprecated
(String, QrImage?, String?) generateComandaText(dynamic data, int printerSize) {
  QrImage? qrImage;
  String? qrString;
  final ReceiptTxtBuilder receiptBuilder = ReceiptTxtBuilder(
    linesLength: printerSize - 26,
  );
  Map<String, dynamic> company = data["company"] ?? {};
  Map<String, Map> fields = data["electronic_invoice"]?["fields"] ?? {};

  // Encabezado
  receiptBuilder.addHeaderLines([
    "${company["name"]?.toString().toUpperCase()}",
  ]).addSep();
  // Factura centrada
  if (data["billing"] != null && fields["voucher_type"] != null) {
    receiptBuilder.addLines([
      fields["voucher_type"]?["Desc"]?.toString().toUpperCase() ?? "",
      "Código: ${fields["voucher_type"]?["Id"] ?? ""}",
    ]).addSep();
  }
  // Datos de la factura
  Map vendedor = data["seller"] ?? {};
  receiptBuilder.addLines([
    "NRO: ${data["code"] ?? ""}",
    "CLIENTE: ${data["client"]?["name"] ?? "CONSUMIDOR FINAL"}",
    "FECHA:".expand("${data["date"] ?? ""}", printerSize - 26),
    "HORA:".expand("${data["hour"] ?? ""}", printerSize - 26),
    "Vendedor: ${vendedor["name"] ?? ""}",
    "TIPO: ${data["invoice_type"]?["name"] ?? ""}",
    ...((data["billing"] != null)
        ? ["CONCEPTO: ${fields["concept_type"]?["Desc"] ?? ""}"]
        : []),
    ...((data["tables"] != null)
        ? data["tables"].map((table) {
            return "MESA: ${table["name"] ?? ""} SALA ${table["living_room"]?["name"] ?? ""}";
          })
        : []),
  ]).addSep();

  // Detalle
  receiptBuilder.addItem("Artículo".toUpperCase(), "CANT");

  double totalQuantity = 0.0;
  for (var prod in data["products"] ?? []) {
    double cantidad = double.parse("${prod["pivot"]?["amount"] ?? "0.0"}");
    totalQuantity += cantidad;
    receiptBuilder.addItem(
      prod["name"]?.toString().toUpperCase() ?? "",
      cantidad.toStringAsFixed(2),
    );
  }

  receiptBuilder.addSep();
  receiptBuilder
      .addItem("TOTAL:", totalQuantity.toStringAsFixed(2))
      .addSep()
      .addLines([
        // CAE y Vto
        ...(data["billing"] != null && fields["cae"] != null)
            ? [
                "CAE: ${fields["cae"] ?? ""}",
                "Vto: ${fields["caef_ch_vto"] ?? ""}",
                ...((data["billing"] != null) ? [] : []),
              ]
            : [],
      ])
      .addLines([
        "\n" * 1,
        "¡Gracias por su compra!".toUpperCase(),
        "\n",
      ], center: true);

  if (data["billing"] != null) {
    (qrImage, qrString) = generate_afip_qr(data, company, fields);
  }

  return (receiptBuilder.build(), qrImage, qrString);
}
