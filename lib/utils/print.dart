import "package:windows_printer/windows_printer.dart";
import "../models/printer.dart";

Future<List<Printer>> getPrinters() async {
  try {
    final printers = await WindowsPrinter.getAvailablePrinters()
        .asStream()
        .asyncExpand(
          (printerStrings) => Stream.fromFutures(
            printerStrings.map(WindowsPrinter.getPrinterProperties),
          ),
        )
        .map(
          (printerProps) => Printer(
            name: printerProps["name"],
            identifier: printerProps["name"],
            type: "local",
          ),
        )
        .toList();
    return printers;
  } catch (e) {
    return [];
  }
}
