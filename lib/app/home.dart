import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:qbitsinc_printer_manager/constants/events.dart";
import "package:qbitsinc_printer_manager/store/app_main_store.dart";
import "package:qbitsinc_printer_manager/store/error_store.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _cuitController = TextEditingController();
  WebSocketChannel? _websocketChannel;
  late StreamSubscription<SysNotification> _subs;

  @override
  void initState() {
    super.initState();
    // Read a config.json and find cuit value and print it
    _connectToServer();
    setState(() {
      _subs = ErrorStore.instance.stream.listen((event) {
        if (!event.show) {
          return;
        }
        _showAlertDialog(event.title, event.message);
        AppMainStore.instance.update(
          AppMainState(status: AppStatus.disconnected),
        );
      });
    });
  }

  @override
  void dispose() {
    _cuitController.dispose();
    _subs.cancel();
    super.dispose();
  }

  void _connectToServer() {
    try {
      final socket = WebSocketChannel.connect(
        Uri(host: "localhost", port: 8000, scheme: "ws", path: "/ws"),
      );
      setState(() {
        _websocketChannel = socket;
      });
      socket.stream.listen(
        (event) {
          try {
            final data = jsonDecode(event);

            if (data["event"] == ChannelEventsType.CONNECTED.value) {
              AppMainStore.instance.update(
                AppMainState(status: AppStatus.connected),
              );
            }
            if (data["event"] == ChannelEventsType.DISCONNECTED.value) {
              AppMainStore.instance.update(
                AppMainState(status: AppStatus.disconnected),
              );
            }
            if (data["event"] == ChannelEventsType.ERROR.value) {
              AppMainStore.instance.update(
                AppMainState(status: AppStatus.error, message: data["message"]),
              );
            }
            if (data["event"] == ChannelEventsType.RECEIVING.value) {
              AppMainStore.instance.update(
                AppMainState(
                  status: AppStatus.receiving,
                  message: data["message"],
                ),
              );
            }
            if (data["event"] == ChannelEventsType.PRINTING.value) {
              AppMainStore.instance.update(
                AppMainState(
                  status: AppStatus.printing,
                  message: data["message"],
                ),
              );
            }
            if (data["event"] == ChannelEventsType.SENDING_PRINTERS.value) {
              AppMainStore.instance.update(
                AppMainState(
                  status: AppStatus.sendingPrinters,
                  message: data["message"],
                ),
              );
            }
            if (data["event"] == ChannelEventsType.CONNECTING.value) {
              AppMainStore.instance.update(
                AppMainState(
                  status: AppStatus.connecting,
                  message: data["message"],
                ),
              );
            }
          } catch (e) {
            print(e);
          }
        },
        onError: (_) {
          socket.sink.close();
          setState(() {
            _websocketChannel = null;
          });
        },
        onDone: () {
          socket.sink.close();
          setState(() {
            _websocketChannel = null;
          });
        },
      );
      socket.sink.add(
        jsonEncode({"event": ChannelEventsType.GET_CURRENT_STATUS.value}),
      );
    } catch (e) {
      ErrorStore.instance.update(
        SysNotification(show: true, title: "An error occur", message: "$e"),
      );
    }
  }

  void _saveConfigCUIT() {
    if (_websocketChannel == null) {
      _connectToServer();
    }
    _websocketChannel?.sink.add(
      jsonEncode({
        "event": ChannelEventsType.CONNECTING.value,
        "payload": {"cuit": _cuitController.text},
      }),
    );
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
    AppMainStore.instance.update(AppMainState(status: AppStatus.disconnected));
    setState(() {
      _websocketChannel?.sink.close();
      _websocketChannel = null;
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
                  Center(
                    child: Image.asset(
                      "assets/images/printer-ui-win.png",
                      width: 325,
                      height: 250,
                    ),
                  ),
                  Expanded(
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
                        Expanded(
                          child: StreamBuilder(
                            stream: AppMainStore.instance.stream,
                            builder: (context, snapshot) {
                              switch (snapshot.data?.status) {
                                case AppStatus.connected:
                                  return Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 16.0),
                                        child: ElevatedButton(
                                          onPressed: _disconnect,
                                          child: Text("Disconnect"),
                                        ),
                                      ),
                                    ],
                                  );
                                case AppStatus.connecting:
                                  return Column(
                                    spacing: 16.0,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 24.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text("Connecting to app..."),
                                        ],
                                      ),
                                    ],
                                  );
                                case AppStatus.sendingPrinters:
                                  return Column(
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
                                  );
                                case AppStatus.receiving:
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          snapshot.data?.message ??
                                              "Receiving...",
                                        ),
                                      ),
                                    ],
                                  );
                                case AppStatus.printing:
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          snapshot.data?.message ??
                                              "Printing...",
                                        ),
                                      ),
                                    ],
                                  );
                                case AppStatus.error:
                                default:
                                  return Column(
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
                                  );
                              }
                            },
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
