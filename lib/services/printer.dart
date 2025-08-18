import "dart:io";
import "dart:typed_data";
import "package:flutter/foundation.dart";
import "package:printer_ui_win/constants/env.dart";
import "package:printer_ui_win/services/ticket.dart";
import "package:windows_printer/windows_printer.dart";

Future<void> printTicket(String destination, dynamic data) async {
  var (content, _, _) = generateTicketText(data);
  try {
    await WindowsPrinter.printRichTextDocument(
      printerName: destination,
      content: content,
      fontSize: int.parse(EnvVariables.receiptFontSize ?? "10"),
      fontName: EnvVariables.receiptFontName ?? "Arial",
    );
  } catch (e) {
    throw Exception("Error sending ticket to printer at $destination: $e");
  }
}

Future<void> printNetworkTicket(String destination, dynamic data) async {
  try {
    // 1. Build the receipt data using the same logic as local printing.
    var receipt = generateTicketReceipt(data);
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

Future<void> printInvoice(dynamic data, String destination) async {
  print("Printing invoice to $destination and data: $data");
  // Use a more robust regex to check for an IPv4 address format.
  if (RegExp(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$").hasMatch(destination)) {
    await printNetworkTicket(destination, data);
  } else {
    await printTicket(destination, data);
  }
}
