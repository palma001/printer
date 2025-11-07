import "dart:io";
import "dart:typed_data";

import "package:flutter/foundation.dart";
import "package:printing/printing.dart";
import "package:qbitsinc_printer_manager/services/ticket.dart";
import "package:qbitsinc_printer_manager/store/app_main_store.dart";

Future<void> printTicket(
  String destination,
  dynamic data,
  int printerSize,
) async {
  AppMainStore.instance.update(
    AppMainState(
      status: AppStatus.printing,
      message: "Printing Document to ${destination}",
    ),
  );
  Uint8List contentPDF = await generatePDFReceipt(data, printerSize);
  try {
    Printer printer = await Printing.listPrinters()
        .asStream()
        .map(
          (printers) =>
              printers.firstWhere((printer) => printer.name == destination),
        )
        .first;
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) => contentPDF,
    );
    AppMainStore.instance.update(AppMainState(status: AppStatus.connected));
  } catch (e) {
    if (e is StateError) {
      throw Exception("Printer: $destination, not found: $e");
    }
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
    var receipt = await generatePDFReceipt(data, printerSize);
    Uint8List receiptUintList = Uint8List.fromList(receipt);

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
