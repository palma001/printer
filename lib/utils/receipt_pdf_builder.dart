import "package:flutter/services.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pdfw;
import "package:printer_ui_win/constants/env.dart";
import "package:printing/printing.dart";

class _Item {
  String description;
  double units;
  double unitPrice;
  double total;
  _Item({
    this.description = "",
    this.units = 0,
    this.unitPrice = 0,
    this.total = 0,
  });
}

class _Line {
  String left;
  String right;
  pdfw.WrapAlignment align;
  pdfw.WrapAlignment runAlignment;
  pdfw.TextStyle textStyle = pdfw.TextStyle();
  _Line({
    this.right = "",
    this.left = "",
    this.align = pdfw.WrapAlignment.start,
    this.runAlignment = pdfw.WrapAlignment.start,
    pdfw.TextStyle? style,
  }) {
    textStyle = style != null ? textStyle.merge(style) : textStyle;
  }
}

class _ReceiptPDFDocument {
  PdfPageFormat pageFormat;
  late pdfw.Document document;
  late pdfw.EdgeInsetsGeometry margin;

  _ReceiptPDFDocument({
    required this.pageFormat,
    pdfw.EdgeInsetsGeometry? margin,
  }) {
    document = pdfw.Document();
    this.margin = margin ?? pdfw.EdgeInsets.fromLTRB(2.0, 2.0, 2.0, 2.0);
  }

  Future<Uint8List> build({List<pdfw.Widget> content = const []}) async {
    pdfw.Font fontBold = await PdfGoogleFonts.robotoBold();
    pdfw.Font fontBase = await PdfGoogleFonts.robotoRegular();
    document.addPage(
      pdfw.Page(
        pageFormat: pageFormat,
        margin: margin,
        theme: pdfw.ThemeData(
          defaultTextStyle: pdfw.TextStyle(
            font: fontBase,
            fontBold: fontBold,
            fontBoldItalic: pdfw.Font.timesBoldItalic(),
            fontItalic: pdfw.Font.timesBoldItalic(),
            fontSize: double.parse(EnvVariables.receiptFontSize ?? "8"),
          ),
        ),
        build: (pdfw.Context context) {
          return pdfw.Column(children: content);
        },
      ),
    );
    return document.save();
  }

  static pdfw.Widget Line(_Line line) {
    return pdfw.Row(
      mainAxisAlignment: pdfw.MainAxisAlignment.start,
      children: [
        pdfw.Expanded(
          child: pdfw.Wrap(
            direction: pdfw.Axis.horizontal,
            alignment: line.align,
            runAlignment: line.runAlignment,
            children: [
              pdfw.Text(line.left, style: line.textStyle),
              pdfw.Text(line.right, style: line.textStyle),
            ],
          ),
        ),
      ],
    );
  }

  static pdfw.Widget Header(
    List<_Line> lines, {
    pdfw.ImageProvider? headerLogo,
  }) {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [
          headerLogo != null
              ? pdfw.Center(
                  child: pdfw.Image(
                    headerLogo,
                    height: 100,
                    fit: pdfw.BoxFit.contain,
                  ),
                )
              : pdfw.Row(
                  children: [
                    pdfw.Expanded(
                      child: pdfw.Container(
                        color: PdfColor.fromHex("#a0a0a0"),
                        height: 0,
                      ),
                    ),
                  ],
                ),
          pdfw.SizedBox.square(dimension: 4),
          ...lines.map((line) => _ReceiptPDFDocument.Line(line)),
        ],
      ),
    );
  }

  static pdfw.Widget Separator() {
    return pdfw.Container(
      height: 0.1,
      width: double.infinity,
      color: PdfColor.fromHex("#000000"),
    );
  }

  static pdfw.Widget CashierInfo(
    List<_Line> lines, {
    String desc = "",
    String type = "",
    String cod = "",
  }) {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [
          pdfw.Row(
            children: [
              pdfw.SizedBox.square(dimension: 8),
              pdfw.Column(
                crossAxisAlignment: pdfw.CrossAxisAlignment.center,
                children: [
                  pdfw.Text(
                    desc,
                    style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                  ),
                  pdfw.Text("COD $cod"),
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
                child: pdfw.Text(
                  type,
                  style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                ),
              ),
            ],
          ),
          ...lines.map((line) => _ReceiptPDFDocument.Line(line)),
        ],
      ),
    );
  }

  static pdfw.Widget ClientInfo([List<_Line> lines = const []]) {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 2, bottom: 2),
      child: pdfw.Column(
        children: [...lines.map((line) => _ReceiptPDFDocument.Line(line))],
      ),
    );
  }

  static pdfw.Widget Items([List<_Item> items = const []]) {
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
                  children: [pdfw.Text("")],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Text(
                      "Unid.",
                      style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Text(
                      "\$xUnid",
                      style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Text(
                      "\$Total",
                      style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: 2),
          Separator(),
          pdfw.SizedBox.square(dimension: 2),
          ...items.map((item) {
            return pdfw.Column(
              children: [
                pdfw.Row(
                  children: [
                    pdfw.Expanded(
                      flex: 3,
                      child: pdfw.Wrap(
                        direction: pdfw.Axis.horizontal,
                        alignment: pdfw.WrapAlignment.start,
                        children: [pdfw.Text(item.description)],
                      ),
                    ),
                    pdfw.Expanded(flex: 1, child: pdfw.Container()),
                  ],
                ),
                pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Expanded(
                      flex: 1,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [pdfw.Text("")],
                      ),
                    ),
                    pdfw.Expanded(
                      flex: 2,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [
                          pdfw.Text(
                            item.units.toString(),
                            style: pdfw.TextStyle(
                              fontWeight: pdfw.FontWeight.bold,
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
                          pdfw.Text(
                            "\$${item.unitPrice.toString()}",
                            style: pdfw.TextStyle(
                              fontWeight: pdfw.FontWeight.bold,
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
                          pdfw.Text(
                            "\$${item.total.toString()}",
                            style: pdfw.TextStyle(
                              fontWeight: pdfw.FontWeight.bold,
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

  static pdfw.Widget CommandaItems([List<_Item> items = const []]) {
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
                  children: [pdfw.Text("")],
                ),
              ),
              pdfw.Expanded(
                flex: 2,
                child: pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Text(
                      "Unidades",
                      style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pdfw.SizedBox.square(dimension: 2),
          Separator(),
          pdfw.SizedBox.square(dimension: 2),
          ...items.map((item) {
            return pdfw.Column(
              children: [
                pdfw.Row(
                  children: [
                    pdfw.Expanded(
                      flex: 3,
                      child: pdfw.Wrap(
                        direction: pdfw.Axis.horizontal,
                        alignment: pdfw.WrapAlignment.start,
                        children: [pdfw.Text(item.description)],
                      ),
                    ),
                    pdfw.Expanded(flex: 1, child: pdfw.Container()),
                  ],
                ),
                pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.end,
                  children: [
                    pdfw.Expanded(
                      flex: 1,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [pdfw.Text("")],
                      ),
                    ),
                    pdfw.Expanded(
                      flex: 2,
                      child: pdfw.Row(
                        mainAxisAlignment: pdfw.MainAxisAlignment.end,
                        children: [
                          pdfw.Text(
                            item.units.toString(),
                            style: pdfw.TextStyle(
                              fontWeight: pdfw.FontWeight.bold,
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

  static pdfw.Widget Total({double total = 0, double? totalNoDiscount}) {
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
              spacing: 4,
              runAlignment: pdfw.WrapAlignment.center,
              children: [
                pdfw.Text(
                  "Imp. Total:",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontSize:
                        (double.parse(EnvVariables.receiptFontSize ?? "8")) + 1,
                  ),
                ),
                pdfw.Text(
                  "\$$total",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontSize:
                        (double.parse(EnvVariables.receiptFontSize ?? "8")) + 1,
                  ),
                ),
              ],
            ),
          ),
          ?totalNoDiscount == null
              ? null
              : pdfw.Wrap(
                  direction: pdfw.Axis.horizontal,
                  alignment: pdfw.WrapAlignment.center,
                  children: [
                    pdfw.Text(
                      "Total Sin Desc. \$$totalNoDiscount",
                      style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  static pdfw.Widget CommandaTotal({
    double total = 0,
    double totalNoDiscount = 0,
  }) {
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
                pdfw.Text(
                  "Total:",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontSize:
                        double.parse(EnvVariables.receiptFontSize ?? "10") + 1,
                  ),
                ),
                pdfw.Text(
                  "$total",
                  style: pdfw.TextStyle(
                    fontWeight: pdfw.FontWeight.bold,
                    fontSize:
                        double.parse(EnvVariables.receiptFontSize ?? "10") + 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pdfw.Widget TaxInformation({
    List<_Line> fiscal = const [],
    List<_Line> bottom = const [],
    Uint8List? imageBytes,
    String? qrCodeData,
  }) {
    return pdfw.Container(
      margin: pdfw.EdgeInsets.only(top: 8),
      child: pdfw.Column(
        children: [
          pdfw.SizedBox.square(
            dimension: (double.parse(EnvVariables.receiptFontSize ?? "10") / 2),
          ),
          ...fiscal
              .map(
                (line) => [
                  _ReceiptPDFDocument.Line(line),
                  pdfw.SizedBox.square(
                    dimension:
                        (double.parse(EnvVariables.receiptFontSize ?? "10") /
                        2),
                  ),
                ],
              )
              .fold(
                [],
                (previousValue, element) => [...previousValue, ...element],
              ),
          ?imageBytes == null || qrCodeData == null
              ? null
              : pdfw.Row(
                  mainAxisAlignment: pdfw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pdfw.CrossAxisAlignment.end,
                  children: [
                    pdfw.Expanded(
                      flex: 6,
                      child: pdfw.AspectRatio(
                        aspectRatio: 1 / 1,
                        child: pdfw.Container(
                          margin: pdfw.EdgeInsets.only(right: 4),
                          child: pdfw.BarcodeWidget(
                            data: qrCodeData,
                            barcode: pdfw.Barcode.qrCode(),
                            height: 100,
                          ),
                        ),
                      ),
                    ),
                    pdfw.Expanded(
                      flex: 5,
                      child: pdfw.Container(
                        height: 100,
                        padding: pdfw.EdgeInsets.only(bottom: 16),
                        child: pdfw.Image(pdfw.MemoryImage(imageBytes)),
                      ),
                    ),
                  ],
                ),
          pdfw.SizedBox.square(
            dimension: (double.parse(EnvVariables.receiptFontSize ?? "10") / 2),
          ),
          ...bottom
              .map(
                (line) => [
                  _ReceiptPDFDocument.Line(line),
                  pdfw.SizedBox.square(
                    dimension:
                        (double.parse(EnvVariables.receiptFontSize ?? "10") /
                        2),
                  ),
                ],
              )
              .fold(
                [],
                (previousValue, element) => [...previousValue, ...element],
              ),
        ],
      ),
    );
  }
}

enum ReceiptType { command, receipt }

class ReceiptPDFBuilder {
  late (List<_Line>, String?) _headerLines;
  late (List<_Line>, String?, String?, String?) _cashierInfoLines;
  late List<_Line> _clientInfoLines;
  late List<_Item> _items;
  late List<_Line> _footer_top;
  late List<_Line> _footer_bottom;
  late (double, double) _total;

  static _Line Line({
    String left = "",
    String right = "",
    pdfw.WrapAlignment align = pdfw.WrapAlignment.start,
    pdfw.WrapAlignment runAlignment = pdfw.WrapAlignment.start,
    pdfw.TextStyle? style,
  }) {
    return _Line(
      left: left,
      right: right,
      align: align,
      runAlignment: runAlignment,
      style: style,
    );
  }

  static _Item Item({
    String description = "",
    double units = 0,
    double unitPrice = 0,
    double total = 0,
  }) {
    return _Item(
      description: description,
      units: units,
      unitPrice: unitPrice,
      total: total,
    );
  }

  ReceiptPDFBuilder() {
    _headerLines = ([], null);
    _cashierInfoLines = ([], null, null, null);
    _clientInfoLines = [];
    _items = [];
    _footer_bottom = [];
    _footer_top = [];
    _total = (0, 0);
  }

  ReceiptPDFBuilder addSeparator() {
    _ReceiptPDFDocument.Separator();
    return this;
  }

  ReceiptPDFBuilder addInHeader(List<_Line> lines, {String? headerImgUrl}) {
    _headerLines = (
      [..._headerLines.$1, ...lines],
      headerImgUrl ?? _headerLines.$2,
    );
    return this;
  }

  ReceiptPDFBuilder addInCashierInfo(
    List<_Line> line, {
    String? desc,
    String? type,
    String? cod,
  }) {
    _cashierInfoLines = (
      [..._cashierInfoLines.$1, ...line],
      desc ?? _cashierInfoLines.$2,
      type ?? _cashierInfoLines.$3,
      cod ?? _cashierInfoLines.$4,
    );
    return this;
  }

  ReceiptPDFBuilder addInClientInfo(List<_Line> line) {
    _clientInfoLines.addAll(line);
    return this;
  }

  ReceiptPDFBuilder addInFooterTop(List<_Line> line) {
    _footer_top.addAll(line);
    return this;
  }

  ReceiptPDFBuilder addInFooterBottom(List<_Line> line) {
    _footer_bottom.addAll(line);
    return this;
  }

  ReceiptPDFBuilder addItem(List<_Item> item) {
    _items.addAll(item);
    return this;
  }

  ReceiptPDFBuilder addItems(List<_Item> item) {
    _items.addAll(item);
    return this;
  }

  ReceiptPDFBuilder addTotal({double total = 0, double totalNoDiscount = 0}) {
    _total = (total, totalNoDiscount);
    return this;
  }

  Future<Uint8List> build({
    PdfPageFormat pageFormat = PdfPageFormat.roll80,
    ReceiptType type = ReceiptType.receipt,
    String? qrCodeData = "",
  }) async {
    _ReceiptPDFDocument document = _ReceiptPDFDocument(pageFormat: pageFormat);
    pdfw.ImageProvider? headerImage = _headerLines.$2 == null
        ? null
        : await networkImage(_headerLines.$2!);
    ByteData? imgData = qrCodeData == null
        ? null
        : await rootBundle.load("assets/images/arca.png");
    return document.build(
      content: [
        _ReceiptPDFDocument.Header(_headerLines.$1, headerLogo: headerImage),
        _ReceiptPDFDocument.Separator(),
        _ReceiptPDFDocument.CashierInfo(
          _cashierInfoLines.$1,
          desc: _cashierInfoLines.$2 ?? "",
          type: _cashierInfoLines.$3 ?? "",
          cod: _cashierInfoLines.$4 ?? "",
        ),
        _ReceiptPDFDocument.Separator(),
        _ReceiptPDFDocument.ClientInfo(_clientInfoLines),
        _ReceiptPDFDocument.Separator(),
        type == ReceiptType.receipt
            ? _ReceiptPDFDocument.Items(_items)
            : _ReceiptPDFDocument.CommandaItems(_items),
        _ReceiptPDFDocument.Separator(),
        type == ReceiptType.receipt
            ? _ReceiptPDFDocument.Total(
                total: _total.$1,
                totalNoDiscount: _total.$2,
              )
            : _ReceiptPDFDocument.CommandaTotal(
                total: _total.$1,
                totalNoDiscount: _total.$2,
              ),
        _ReceiptPDFDocument.TaxInformation(
          fiscal: _footer_top,
          bottom: _footer_bottom,
          imageBytes: imgData?.buffer.asUint8List(),
          qrCodeData: qrCodeData,
        ),
      ],
    );
  }
}
