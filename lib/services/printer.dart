import "dart:io";
import "dart:typed_data";

import "package:flutter/foundation.dart";
import "package:printer_ui_win/services/ticket.dart";
import "package:printing/printing.dart";

Future<void> printTicket(
  String destination,
  dynamic data,
  int printerSize,
) async {
  // var (content, _, _) = (data["type"] ?? "").toLowerCase() == "command"
  //     ? generateComandaText(data, printerSize)
  //     : generateTicketText(data, printerSize);
  Uint8List contentPDF = await generatePDFReceipt(data, printerSize);
  Printer printer = await Printing.listPrinters()
      .asStream()
      .map(
        (printers) =>
            printers.firstWhere((printer) => printer.name == destination),
      )
      .first;
  try {
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) => contentPDF,
    );
    // await WindowsPrinter.printRichTextDocument(
    //   printerName: destination,
    //   content: content,
    //   fontSize: int.parse(EnvVariables.receiptFontSize ?? "10"),
    //   fontName: EnvVariables.receiptFontName ?? "Arial",
    // );
  } catch (e) {
    throw Exception("Error sending ticket to printer at $destination: $e");
  }
}

Future<void> printNetworkTicket(
  String destination,
  dynamic data,
  int printerSize,
) async {
  try {
    // 1. Build the receipt data using the same logic as local printing.
    var receipt = generateTicketReceipt(data, printerSize);
    Uint8List receiptUintList = Uint8List.fromList(receipt.build());

    // 2. Connect to the network printer via raw TCP socket on port 9100.
    final socket = await Socket.connect(
      destination,
      9100,
      timeout: const Duration(seconds: 5),
    );

    // 3. Send the data.
    socket.add(receiptUintList);
    await socket.flush();

    // 4. Close the socket.
    await socket.close();
  } catch (e) {
    throw Exception(
      "Error sending ticket to network printer at $destination: $e",
    );
  }
}

Future<void> printInvoice(
  dynamic data,
  String destination, [
  int printerSize = 58,
]) async {
  print("Printing invoice to $destination and data: $data");
  // Use a more robust regex to check for an IPv4 address format.
  if (RegExp(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$").hasMatch(destination)) {
    await printNetworkTicket(destination, data, printerSize);
  } else {
    await printTicket(destination, data, printerSize);
  }
}
