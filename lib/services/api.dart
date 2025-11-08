import "dart:convert";

import "package:http/http.dart" as http;
import "package:qbitsinc_printer_manager/constants/env.dart";
import "package:qbitsinc_printer_manager/models/printer.dart";

Future<String> registerDeviceToAPI(
  String cuit,
  String deviceId,
  List<Printer> printers,
) async {
  if (EnvVariables.apiUrl == null) {
    throw Exception("API URL not found");
  }
  Map<String, dynamic> payload = {
    "cuit": cuit,
    "device_id": deviceId,
    "printers": printers.map((printer) => printer.toMap()).toList(),
  };
  print(
    "Sending printer to API ${EnvVariables.apiUrl} with payload ${json.encode(payload)}",
  );
  var response = await http.post(
    Uri.parse(EnvVariables.apiUrl!),
    body: json.encode(payload),
    headers: {"Content-Type": "application/json"},
  );
  if (response.statusCode >= 400 || response.statusCode < 200) {
    throw Exception("Error saving device ${response.statusCode}");
  }
  return response.statusCode.toString();
}
