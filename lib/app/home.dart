import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:qbitsinc_printer_manager/models/printer.dart";
import "package:qbitsinc_printer_manager/services/api.dart";
import "package:qbitsinc_printer_manager/services/websocket.dart";
import "package:qbitsinc_printer_manager/store/error_store.dart";
import "package:qbitsinc_printer_manager/utils/print.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum _MyHomeStatus {
  disconnected,
  connected,
  sendingPrinters,
  connectingSocket,
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _cuitController = TextEditingController();
  List<Printer> _printerList = [];
  WebSocketChannel? _websocketChannel;
  _MyHomeStatus _status = _MyHomeStatus.disconnected;
  late StreamSubscription<SysNotification> _subs;

  @override
  void initState() {
    super.initState();
    // Read a config.json and find cuit value and print it
    _loadConfig();
    setState(() {
      _subs = ErrorStore.instance.stream.listen((event) {
        if (!event.show) {
          return;
        }
        _showAlertDialog(event.title, event.message);
        setState(() {
          _status = _MyHomeStatus.disconnected;
        });
      });
    });
  }

  @override
  void dispose() {
    _cuitController.dispose();
    super.dispose();
    _subs.cancel();
  }

  Future<void> _loadConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/config.json";
      final file = File(path);

      if (!await file.exists()) {
        await file.writeAsString(jsonEncode({}));
      }

      final String jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);
      final String? cuit = data["cuit"];
      print("CUIT from $path: $cuit");
      if (cuit != null) {
        _cuitController.text = cuit;
        _loadPrinters();
      }
    } catch (e) {
      ErrorStore.instance.update(
        SysNotification(
          show: true,
          title: "An error occur",
          message: "Error handling config.json: $e",
        ),
      );
    }
  }

  void _saveConfigCUIT() async {
    if (_cuitController.text.isEmpty) {
      _showAlertDialog("Validation Error", "CUIT cannot be empty.");
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/config.json";
      final file = File(path);

      final String jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);

      data["cuit"] = _cuitController.text.trim();
      data["device_id"] = Platform.localHostname.trim();

      await file.writeAsString(json.encode(data));
      _loadPrinters();
      (_cuitController.text, Platform.localHostname, _printerList);
    } catch (e) {
      print("Error saving config.json: $e");
      ErrorStore.instance.update(
        SysNotification(
          show: true,
          title: "Error",
          message: "An error occurred while saving the CUIT.",
        ),
      );
    }
  }

  void _loadPrinters() async {
    try {
      setState(() {
        _status = _MyHomeStatus.sendingPrinters;
      });
      var printers = await getPrinters();
      setState(() {
        _printerList = printers;
      });
      var cuitTrim = _cuitController.text.trim();
      try {
        await registerDeviceToAPI(cuitTrim, Platform.localHostname, printers);
        setState(() {
          _status = _MyHomeStatus.connectingSocket;
        });
      } catch (e) {
        ErrorStore.instance.update(
          SysNotification(show: true, title: "An error occur", message: "$e"),
        );
        print("$e");
        return;
      }
      var (subs, channel) = connectToPusher(printers, cuitTrim);
      subs.onDone(() {
        setState(() {
          _status = _MyHomeStatus.disconnected;
        });
      });
      setState(() {
        _status = _MyHomeStatus.connected;
        _websocketChannel = channel;
      });
    } catch (e) {
      ErrorStore.instance.update(
        SysNotification(show: true, title: "An error occur", message: "$e"),
      );
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
              child: const Text("OK"),
              onPressed: () {
                ErrorStore.instance.update(SysNotification(show: false));
                Navigator.of(dialogContext).pop();
              },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: 320),
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          spacing: 4,
                          children: [
                            Text(
                              "Qbits Printer Manager",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "v0.20",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
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
                            : _status == _MyHomeStatus.sendingPrinters
                            ? Expanded(
                                child: Column(
                                  spacing: 16.0,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 24.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [Text("Sending printers...")],
                                    ),
                                  ],
                                ),
                              )
                            : _status == _MyHomeStatus.connectingSocket
                            ? Expanded(
                                child: Column(
                                  spacing: 16.0,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 24.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [Text("Connecting to app...")],
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
          ],
        ),
      ),
    );
  }
}
