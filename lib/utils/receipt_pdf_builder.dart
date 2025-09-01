import "dart:typed_data";

import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pdfw;

class ReceiptPDFBuilder {
  late pdfw.Document document;
  PdfPageFormat pageFormat = PdfPageFormat.roll57;
  pdfw.EdgeInsetsGeometry margin = pdfw.EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0);
  pdfw.TextStyle textStyle = pdfw.TextStyle(
    font: pdfw.Font.courier(),
    fontSize: 8,
  );

  ReceiptPDFBuilder() {
    document = pdfw.Document();
  }
  Future<Uint8List> build() async {
    // pdfw.ImageProvider headerLogo = await networkImage("");
    document.addPage(
      pdfw.Page(
        pageFormat: pageFormat,
        margin: margin,
        build: (pdfw.Context context) {
          return pdfw.Column(
            children: [
              _Header(/*headerLogo*/),
              _Separator(),
              _CashierInfo(),
              _Separator(),
              _ClientInfo(),
              _Separator(),
              _Items(),
              _Separator(),
              _Total(),
              _TaxInformation(),
            ],
          );
        },
      ),
    );
    return document.save();
  }

  pdfw.Text _Text(String text, {pdfw.TextStyle? style}) {
    pdfw.TextStyle mergeStyle = style != null
        ? textStyle.merge(style)
        : textStyle;
    return pdfw.Text(text, softWrap: true, style: mergeStyle);
  }

  pdfw.Widget _Header([pdfw.ImageProvider? headerLogo]) {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [
          ?headerLogo != null
              ? pdfw.Center(child: pdfw.Image(headerLogo))
              : pdfw.Row(
                  children: [
                    pdfw.Expanded(
                      child: pdfw.Container(
                        color: PdfColor.fromHex("#a0a0a0"),
                        height: 100,
                      ),
                    ),
                  ],
                ),
          pdfw.SizedBox.square(dimension: 4),
          pdfw.Wrap(
            direction: pdfw.Axis.horizontal,
            alignment: pdfw.WrapAlignment.center,
            children: [_Text("De Roveta Sergio Dario")],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.spaceBetween,
                  runAlignment: pdfw.WrapAlignment.spaceBetween,
                  spacing: 4,
                  children: [
                    _Text("I.V.A. Resp Inscripto"),
                    _Text("C.U.I.T 20923214454"),
                  ],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.spaceBetween,
                  spacing: 4,
                  children: [
                    _Text("II BB 20923214454"),
                    _Text("F in Act. 05/09/2022"),
                  ],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.start,
                  children: [_Text("Direction: Nemesio Alvarez 298")],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.start,
                  children: [_Text("C P. 1744 - Moreno - Buenos Aires ")],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pdfw.Widget _Separator() {
    return pdfw.Container(
      height: 0.1,
      width: double.infinity,
      color: PdfColor.fromHex("#000000"),
    );
  }

  pdfw.Widget _CashierInfo() {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [
          pdfw.Row(
            children: [
              pdfw.Column(
                crossAxisAlignment: pdfw.CrossAxisAlignment.center,
                children: [
                  _Text(
                    "Factura",
                    style: pdfw.TextStyle(
                      fontWeight: pdfw.FontWeight.bold,
                      fontBold: pdfw.Font.courierBold(),
                    ),
                  ),
                  _Text("COD 06"),
                ],
              ),
              pdfw.SizedBox(width: 8),
              pdfw.Container(
                decoration: pdfw.BoxDecoration(
                  border: pdfw.Border.all(
                    width: 0.1,
                    color: PdfColor.fromHex("#000000"),
                  ),
                ),
                padding: pdfw.EdgeInsets.all(4),
                child: _Text(
                  "B",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontBold: pdfw.Font.courierBold(),
                  ),
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.spaceBetween,
                  spacing: 4,
                  children: [
                    _Text(
                      "No.00002-00196232",
                      style: pdfw.TextStyle(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                    _Text(
                      "Vendor: LISF",
                      style: pdfw.TextStyle(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.spaceBetween,
                  spacing: 4,
                  children: [
                    _Text(
                      "Fecha: 21/08/2025",
                      style: pdfw.TextStyle(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                    _Text(
                      "Hora: 10:20:40",
                      style: pdfw.TextStyle(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pdfw.Widget _ClientInfo() {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.start,
                  children: [_Text("Caja: Final Caja 1 (1)")],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.start,
                  children: [_Text("DNI: 1")],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.start,
                  children: [_Text("Text I.V.A: CONS FINAL")],
                ),
              ),
            ],
          ),
          pdfw.Row(
            children: [
              pdfw.Expanded(
                child: pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.start,
                  children: [_Text("De: Moreno C.P. 1244")],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pdfw.Widget _Items() {
    List<Map<String, dynamic>> items = [
      {
        "description": "Product 1",
        "units": 11.1,
        "unitPrice": 10.11,
        "total": 111.11,
      },
      {
        "description": "Product 2",
        "units": 11.1,
        "unitPrice": 10.11,
        "total": 111.11,
      },
    ];
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [
          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.end,
            children: [
              pdfw.Expanded(
                flex: 1,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [_Text("")],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    _Text(
                      "Unidades",
                      style: textStyle.copyWith(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                  ],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    _Text(
                      "\$ x Unid",
                      style: textStyle.copyWith(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                  ],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    _Text(
                      "\$ Total",
                      style: textStyle.copyWith(
                        fontWeight: pdfw.FontWeight.bold,
                        fontBold: pdfw.Font.courierBold(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Separator(),
          ...items.map((item) {
            return pdfw.Column(
              children: [
                pdfw.Row(
                  children: [
                    pdfw.Expanded(
                      child: pdfw.Wrap(
                        direction: pdfw.Axis.horizontal,
                        alignment: pdfw.WrapAlignment.start,
                        children: [_Text(item["description"])],
                      ),
                    ),
                  ],
                ),
                pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Expanded(
                      flex: 1,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [_Text("")],
                      ),
                    ),
                    pdfw.Expanded(
                      flex: 2,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [
                          _Text(
                            item["units"].toString(),
                            style: textStyle.copyWith(
                              fontWeight: pdfw.FontWeight.bold,
                              fontBold: pdfw.Font.courierBold(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pdfw.Expanded(
                      flex: 2,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [
                          _Text(
                            "\$ ${item["unitPrice"].toString()}",
                            style: textStyle.copyWith(
                              fontWeight: pdfw.FontWeight.bold,
                              fontBold: pdfw.Font.courierBold(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pdfw.Expanded(
                      flex: 2,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [
                          _Text(
                            "\$ ${item["total"].toString()}",
                            style: textStyle.copyWith(
                              fontWeight: pdfw.FontWeight.bold,
                              fontBold: pdfw.Font.courierBold(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  pdfw.Widget _Total() {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 16),
      child: pdfw.Column(
        children: [
          pdfw.Container(
            decoration: pdfw.BoxDecoration(
              border: pdfw.Border.all(
                width: 0.1,
                color: PdfColor.fromHex("#000000"),
              ),
              borderRadius: pdfw.BorderRadius.circular(0),
            ),
            padding: pdfw.EdgeInsets.fromLTRB(8, 12, 8, 12),
            margin: pdfw.EdgeInsets.only(bottom: 8),
            child: pdfw.Wrap(
              direction: pdfw.Axis.horizontal,
              alignment: pdfw.WrapAlignment.spaceBetween,
              runAlignment: pdfw.WrapAlignment.center,
              children: [
                _Text(
                  "Importe Total :",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontBold: pdfw.Font.courierBold(),
                    fontSize: (textStyle.fontSize ?? 10) + 2,
                  ),
                ),
                _Text(
                  "\$ 28252.22",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontBold: pdfw.Font.courierBold(),
                    fontSize: (textStyle.fontSize ?? 10) + 2,
                  ),
                ),
              ],
            ),
          ),
          pdfw.Wrap(
            direction: pdfw.Axis.horizontal,
            alignment: pdfw.WrapAlignment.center,
            children: [
              _Text(
                "Total Sin Descuento \$ 20157.25",
                style: pdfw.TextStyle(
                  fontWeight: pdfw.FontWeight.bold,
                  fontBold: pdfw.Font.courierBold(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pdfw.Widget _TaxInformation() {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 8),
      child: pdfw.Column(
        children: [
          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.start,
            children: [
              pdfw.SizedBox.square(dimension: 4),
              _Text(
                "Fiscal",
                style: pdfw.TextStyle(
                  fontWeight: pdfw.FontWeight.bold,
                  fontBold: pdfw.Font.courierBold(),
                  fontSize: (textStyle.fontSize ?? 10) - 2,
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: ((textStyle.fontSize ?? 10) / 2)),
          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.start,
            children: [
              pdfw.Expanded(
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.spaceAround,
                  children: [
                    _Text(
                      "I.V.A. Contenido",
                      style: textStyle.copyWith(
                        fontSize: (textStyle.fontSize ?? 10) + 2,
                      ),
                    ),
                    pdfw.Row(
                      mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
                      children: [
                        _Text("\$"),
                        _Text(
                          "4848",
                          style: textStyle.copyWith(
                            fontSize: (textStyle.fontSize ?? 10) + 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: ((textStyle.fontSize ?? 10) / 2)),

          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
            children: [_Text("C.A.E.No 75213213518313")],
          ),
          pdfw.SizedBox.square(dimension: ((textStyle.fontSize ?? 10) / 2)),

          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
            children: [
              pdfw.Expanded(
                flex: 4,
                child: pdfw.AspectRatio(
                  aspectRatio: 1 / 1,
                  child: pdfw.Container(
                    color: PdfColor.fromHex("#a0a0a0"),
                    margin: pdfw.EdgeInsets.only(right: 4),
                  ),
                ),
              ),
              pdfw.Expanded(
                flex: 5,
                child: pdfw.AspectRatio(
                  aspectRatio: 1 / 1,
                  child: pdfw.Container(
                    color: PdfColor.fromHex("#a0a0a0"),
                    height: 100,
                  ),
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: ((textStyle.fontSize ?? 10) / 2)),

          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.start,
            children: [
              _Text(
                "Comprobante Autorizado",
                style: pdfw.TextStyle(
                  fontWeight: pdfw.FontWeight.bold,
                  fontBold: pdfw.Font.courierBold(),
                  fontStyle: pdfw.FontStyle.italic,
                  fontItalic: pdfw.Font.timesBoldItalic(),
                  fontSize: (textStyle.fontSize ?? 10) + 2,
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: ((textStyle.fontSize ?? 10) / 2)),

          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.start,
            children: [
              _Text(
                "Esta Administracion Federal no se responsabiliza por sus datos",
                style: textStyle.copyWith(
                  fontSize: (textStyle.fontSize ?? 10) - 2,
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: ((textStyle.fontSize ?? 10) / 2)),
          pdfw.Row(
            mainAxisAlignment: pdfw.MainAxisAlignment.start,
            children: [
              _Text(
                "Ingresados xxxxx",
                style: textStyle.copyWith(
                  fontSize: (textStyle.fontSize ?? 10) - 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
