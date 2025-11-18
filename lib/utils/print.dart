import "package:printing/printing.dart" as prnt;

import "../models/printer.dart";

Future<List<Printer>> getPrinters() async {
  try {
    final printers = await prnt.Printing.listPrinters()
        .asStream()
        .asyncExpand((printerStrings) => Stream.fromIterable(printerStrings))
        .map(
          (printerProps) => Printer(
            name: printerProps.name,
            identifier: printerProps.name,
            type: "local",
          ),
        )
        .toList();
    return printers;
  } catch (e) {
    return [];
  }
}
