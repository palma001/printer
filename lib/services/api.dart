import 'dart:convert';

import 'package:printer_ui_win/constants/env.dart';
import 'package:http/http.dart' as http;
import 'package:printer_ui_win/models/printer.dart';

Future<String> registerDeviceToAPI(
  String cuit,
  String device_id,
  List<Printer> printers,
) async {
  if (EnvVariables.apiUrl == null) {
    throw Exception("API URL not found");
  }
  print("Sending printer to API ${EnvVariables.apiUrl}");
  var response = await http.post(
    Uri.parse(EnvVariables.apiUrl!),
    body: {
      "cuit": cuit,
      "device_id": device_id,
      "printers": json.encode(printers.map((printer) => printer.name).toList()),
    },
  );
  if (response.statusCode == 200) {
    return response.statusCode.toString();
  }
  return "Error saving device";
}
