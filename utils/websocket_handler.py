# websocket_handler.py
import json
import threading
import websocket
from utils.printer import print_invoice

PUSHER_APP_KEY = "baa549b06e82421f4895"
PUSHER_CLUSTER = "us2"
CHANNEL = "comandas"
EVENT_NAME = "NewOrderComanda"

def build_pusher_ws_url():
    clusters = {
        "mt1": "ws.pusherapp.com",
        "us2": "ws-us2.pusher.com",
        "eu": "ws-eu.pusher.com",
        "ap1": "ws-ap1.pusher.com"
    }
    return f"wss://{clusters.get(PUSHER_CLUSTER, 'ws.pusherapp.com')}/app/{PUSHER_APP_KEY}?protocol=7&client=python"

def handle_pusher_message(ws, message, printers, cuit):
    try:
        msg = json.loads(message)
        event = msg.get("event")
        expected_event = f"{EVENT_NAME}_{cuit}"


        if event == "pusher:connection_established":
            ws.send(json.dumps({"event": "pusher:subscribe", "data": {"channel": CHANNEL}}))
            on_open()

        elif event == expected_event:
            payload = json.loads(msg["data"]) if isinstance(msg["data"], str) else msg["data"]
            invoice = payload.get("invoice")
            printer = payload.get("printer")
            if invoice:
                print_invoice(invoice, printer['name'])
            elif printers:
                print_invoice(invoice, printers[0]['identifier'])
    except Exception as e:
        print(f"[X] Failed to process message: {e}")

def on_open():
    try:
        import subprocess
        subprocess.Popen(['powershell', '-Command', 
                          '[System.Reflection.Assembly]::LoadWithPartialName(\"System.Windows.Forms\") | Out-Null; '
                          '[System.Windows.Forms.MessageBox]::Show(\"Conexión con Pusher establecida exitosamente.\", \"Impresora conectada\")'])
    except Exception as e:
        print("[X] Notificación fallida:", e)

def connect_to_pusher(printers, cuit):
    url = build_pusher_ws_url()

    ws = websocket.WebSocketApp(
        url,
        on_open=lambda ws: print("[✅] Connected to Pusher WebSocket."),
        on_message=lambda ws, msg: handle_pusher_message(ws, msg, printers, cuit),
        on_error=lambda ws, err: print("[X] WebSocket error:", err),
        on_close=lambda ws, code, msg: print("[X] WebSocket closed:", msg)
    )

    threading.Thread(target=ws.run_forever, daemon=True).start()

    try:
        while True:
            pass
    except KeyboardInterrupt:
        ws.close()
        print("[⏹️] Listener stopped.")
