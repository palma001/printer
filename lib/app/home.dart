import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:printer_ui_win/models/printer.dart';
import 'package:printer_ui_win/services/api.dart';
import 'package:printer_ui_win/services/websocket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import "package:printer_ui_win/utils/print.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum _MyHomeStatus { disconnected, connected, pending }

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _cuitController = TextEditingController();
  List<Printer> _printerList = [];
  WebSocketChannel? _websocketChannel;
  _MyHomeStatus _status = _MyHomeStatus.disconnected;

  @override
  void initState() {
    super.initState();
    // Read a config.json and find cuit value and print it
    _loadConfig();
  }

  @override
  void dispose() {
    _cuitController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/config.json';
      final file = File(path);

      if (!await file.exists()) {
        await file.writeAsString(jsonEncode({}));
      }

      final String jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);
      final String? cuit = data['cuit'];
      print('CUIT from $path: $cuit');
      if (cuit != null) {
        _cuitController.text = cuit;
        // _loadPrinters();
      }
    } catch (e) {
      print('Error handling config.json: $e');
    }
  }

  void _saveConfigCUIT() async {
    if (_cuitController.text.isEmpty) {
      _showAlertDialog('Validation Error', 'CUIT cannot be empty.');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/config.json';
      final file = File(path);

      final String jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);

      data['cuit'] = _cuitController.text;
      data['device_id'] = Platform.localHostname;

      await file.writeAsString(json.encode(data));
      _loadPrinters();
      (_cuitController.text, Platform.localHostname, _printerList);
    } catch (e) {
      print('Error saving config.json: $e');
      _showAlertDialog('Error', 'An error occurred while saving the CUIT.');
    }
  }

  void _loadPrinters() async {
    try {
      var printers = await getPrinters();
      setState(() {
        _printerList = printers;
        _status = _MyHomeStatus.pending;
      });
      await registerDeviceToAPI(
        _cuitController.text,
        Platform.localHostname,
        printers,
      ).catchError((error) {
        print(error);
        setState(() {
          _status = _MyHomeStatus.disconnected;
        });
        return Future.value("");
      });
      var (_, channel) = connectToPusher(printers, _cuitController.text);
      setState(() {
        _status = _MyHomeStatus.connected;
        _websocketChannel = channel;
      });
    } catch (e) {
      print('Error loading printers: $e');
    }
  }

  Future<void> _showAlertDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _disconnect() {
    setState(() {
      _websocketChannel?.sink.close();
      _websocketChannel = null;
      _status = _MyHomeStatus.disconnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          spacing: 16,
          children: [
            Expanded(
              flex: 1,
              child: Center(
                child: Image.asset(
                  "assets/images/printer-ui-win.png",
                  width: 325,
                  height: 325,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(Platform.localHostname)],
                  ),
                  _status == _MyHomeStatus.disconnected
                      ? Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: TextField(
                                  controller: _cuitController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "Insert CUIT",
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _saveConfigCUIT,
                                child: Text("Connect"),
                              ),
                            ],
                          ),
                        )
                      : _status == _MyHomeStatus.pending
                      ? Expanded(
                          child: Column(
                            spacing: 16.0,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 24.0),
                                child: CircularProgressIndicator(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Text("Connecting...")],
                              ),
                            ],
                          ),
                        )
                      : Expanded(
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 16.0),
                                child: ElevatedButton(
                                  onPressed: _disconnect,
                                  child: Text("Disconnect"),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
