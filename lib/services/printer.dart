import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:printer_ui_win/services/ticket.dart';
import 'package:windows_printer/windows_printer.dart';

Future<void> printTicket(
  String destination,
  List<String> content,
  String qrCode,
) async {
  try {
    var receipt = WPReceiptBuilder(wpPaperSize: WPPaperSize.mm80);
    content.forEach((element) {
      receipt.line(element);
    });
    receipt.addQRCode(qrCode);
    receipt.drawer();
    await WindowsPrinter.printRichTextDocument(
      printerName: destination,
      content: content.join("\n"),
    );
  } catch (e) {
    throw Exception('Error sending ticket to printer at $destination: $e');
  }
}

Future<void> printNetworkTicket(
  String destination,
  List<String> content,
  String qrCode,
) async {
  try {
    // 1. Build the receipt data using the same logic as local printing.
    var receipt = WPReceiptBuilder(wpPaperSize: WPPaperSize.mm80);
    content.forEach((element) {
      receipt.line(element);
    });
    receipt.addQRCode(qrCode);
    final Uint8List data = Uint8List.fromList(receipt.build());

    // 2. Connect to the network printer via raw TCP socket on port 9100.
    final socket = await Socket.connect(
      destination,
      9100,
      timeout: const Duration(seconds: 5),
    );

    // 3. Send the data.
    socket.add(data);
    await socket.flush();

    // 4. Close the socket.
    await socket.close();
  } catch (e) {
    throw Exception(
      'Error sending ticket to network printer at $destination: $e',
    );
  }
}

Future<void> printInvoice(dynamic data, String destination) async {
  print("Printing invoice to $destination and data: $data");
  var (content, qrImage, qrString) = generateTicketText(data);
  // Use a more robust regex to check for an IPv4 address format.
  if (RegExp(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$").hasMatch(destination)) {
    await printNetworkTicket(destination, content, qrString);
  } else {
    await printTicket(destination, content, qrString);
  }
}
