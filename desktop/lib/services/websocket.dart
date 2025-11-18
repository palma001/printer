import "dart:async";
import "dart:convert";

import "package:qbitsinc_printer_manager/constants/env.dart";
import "package:qbitsinc_printer_manager/models/printer.dart";
import "package:qbitsinc_printer_manager/services/printer.dart";
import "package:qbitsinc_printer_manager/store/app_main_store.dart";
import "package:qbitsinc_printer_manager/store/error_store.dart";
import "package:web_socket_channel/web_socket_channel.dart";

String buildPusherWsUrl() {
  const clusters = {
    "mt1": "ws.pusherapp.com",
    "us2": "ws-us2.pusher.com",
    "eu": "ws-eu.pusher.com",
    "ap1": "ws-ap1.pusher.com",
  };
  return "wss://${clusters[EnvVariables.pusherCluster] ?? "ws.pusherapp.com"}/app/${EnvVariables.pusherAppKey}?protocol=7&client=dart";
}

Future<void> handlePusherMessage(
  WebSocketChannel channel,
  String message,
  String cuit,
  List<Printer> printers,
) async {
  try {
    var msg = json.decode(message);
    var event = msg["event"];
    AppMainStore.instance.update(AppMainState(status: AppStatus.connected));
    if (event == "pusher:connection_established") {
      channel.sink.add(
        json.encode({
          "event": "pusher:subscribe",
          "data": {"channel": "comandas"},
        }),
      );
      return;
    }
    if (event == "${EnvVariables.eventName}_$cuit") {
      AppMainStore.instance.update(
        AppMainState(
          status: AppStatus.receiving,
          message: "Receiving Document...",
        ),
      );
      var payload = json.decode(msg["data"]);
      var invoice = payload["invoice"];
      var printer = payload["printer"];
      int printerSize = printer["size"];
      String type = payload["type"];

      if (invoice != null) {
        await printInvoice(invoice, printer["name"], type, printerSize);
      } else if (printers.isNotEmpty) {
        await printInvoice(invoice, printers[0].identifier, type, printerSize);
      }
    }
  } catch (e) {
    ErrorStore.instance.update(
      SysNotification(
        show: true,
        title: "An Error occur",
        message: e.toString(),
      ),
    );
    throw Exception("Failed to process message: $e");
  }
}

(StreamSubscription, WebSocketChannel) connectToPusher(
  List<Printer> printers,
  String cuit,
) {
  var url = buildPusherWsUrl();
  print("Connecting to $url");
  var channel = WebSocketChannel.connect(Uri.parse(url));
  print("Connected to Pusher WebSocket $url");
  var $channelStream = channel.stream.listen(
    (message) => handlePusherMessage(channel, message, cuit, printers),
    onError: (error) => print("WebSocket error: $error"),
    onDone: () => print("WebSocket closed"),
  );
  return ($channelStream, channel);
}
