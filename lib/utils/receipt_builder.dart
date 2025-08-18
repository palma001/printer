import "package:printer_ui_win/constants/env.dart";
import "package:printer_ui_win/utils/string_extension.dart";

class ReceiptBuilder {
  final List<String> _header;
  final List<String> _content;
  final List<String> _footer;
  int linesLength = EnvVariables.receiptPaperSize == "58" ? 40 : 48;
  String get _sep {
    return "-" * linesLength;
  }

  ReceiptBuilder() : _footer = [], _content = [], _header = [];

  String build() {
    return [
      _header.join("\n"),
      _content.join("\n"),
      _footer.join("\n"),
    ].join("\n");
  }

  ReceiptBuilder addSep() {
    _content.add(_sep);
    return this;
  }

  ReceiptBuilder addHeaderLineS(List<String> headerLines) {
    _header.addAll(headerLines.map((line) => line.wrap(linesLength)));
    return this;
  }

  ReceiptBuilder addLines(List<String> lines) {
    _content.addAll(lines.map((line) => line.wrap(linesLength)));
    return this;
  }

  ReceiptBuilder addItem(String left, String right) {
    _content.add(left.expand(right, linesLength).wrap(linesLength));
    return this;
  }

  ReceiptBuilder addFooterLines(List<String> footerLines) {
    _content.addAll(footerLines.map((line) => line.wrap(linesLength)));
    return this;
  }
}
