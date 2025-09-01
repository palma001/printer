import "package:printer_ui_win/utils/string_extension.dart";

class ReceiptTxtBuilder {
  final List<String> _header;
  final List<String> _content;
  final List<String> _footer;
  int linesLength = 32;
  String get _sep {
    return "-" * linesLength;
  }

  ReceiptTxtBuilder({this.linesLength = 32})
    : _footer = [],
      _content = [],
      _header = [];

  String build() {
    return [
      _header.join("\n"),
      _content.join("\n"),
      _footer.join("\n"),
    ].join("\n");
  }

  ReceiptTxtBuilder addSep() {
    _content.add(_sep);
    return this;
  }

  ReceiptTxtBuilder addHeaderLines(
    List<String> headerLines, {
    bool center = false,
  }) {
    _header.addAll(headerLines.map((line) => line.wrap(linesLength, center)));
    return this;
  }

  ReceiptTxtBuilder addLines(List<String> lines, {bool center = false}) {
    _content.addAll(lines.map((line) => line.wrap(linesLength, center)));
    return this;
  }

  ReceiptTxtBuilder addItem(String left, String right) {
    _content.add(left.expand(right, linesLength).wrap(linesLength));
    return this;
  }

  ReceiptTxtBuilder addFooterLines(
    List<String> footerLines, {
    bool center = false,
  }) {
    _content.addAll(footerLines.map((line) => line.wrap(linesLength, center)));
    return this;
  }
}
