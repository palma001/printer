# printer_listener_refactored.py — Clean & optimized 58mm WebSocket printer listener
import os
import json
import socket
import threading
import requests
import platform
import time
import websocket
import win32print

CONFIG_FILE = "config.json"
LARAVEL_API_URL = "https://api-orderwise.qbitsinc.com/api/public/register-device"
# LARAVEL_API_URL = "http://localhost:8000/api/public/register-device"
PUSHER_APP_KEY = "30f8b5b5dfcc8631cb40"
PUSHER_CLUSTER = "us2"
CHANNEL = "comandas"
EVENT_NAME = "NewOrderComanda"

def generate_ticket_text(data):
    """
    Generates a 58mm text ticket from invoice data and company session.
    """
    lines = []
    sep = "-" * 32
    company_session = data.get("company", {})
    fields = data.get("electronic_invoice", {}).get("fields", {}) if data.get("billing") else {}

    # Header
    lines.append(f"RAZON SOCIAL: {company_session.get('name', '').upper()}")
    lines.append(f"DIRECCION: {company_session.get('address', '').upper()}")
    lines.append(f"C.U.I.T: {company_session.get('document_number', '')}")
    
    if data.get("billing"):
        lines.append(f"IIBB: {fields.get('income_brut', '---')}")
        lines.append(f"INICIO ACT: {fields.get('activity_start_date', '---')}")
    
    lines.append(sep)

    # Factura info
    if data.get("billing"):
        lines.append(f"FACTURA {fields.get('voucher_type', {}).get('Desc', '').upper()}")
        lines.append(f"Codigo: {fields.get('voucher_type', {}).get('Id', '')}")
    
    lines.append(f"NRO: {data.get('code', '')}")
    lines.append(f"CLIENTE: {data.get('client', {}).get('name', '')} {data.get('client', {}).get('last_name', '')}")
    lines.append(f"FECHA: {data.get('date', '')}")
    lines.append(f"HORA: {data.get('hour', '')}")
    vendedor = data.get('seller', {})
    lines.append(f"VENDEDOR: {vendedor.get('name', '')} {vendedor.get('last_name', '')}")
    lines.append(f"TIPO: {data.get('invoice_type', {}).get('name', '')}")

    if data.get("billing"):
        lines.append(f"CONCEPTO: {fields.get('concept_type', {}).get('Desc', '')}")

    if data.get("tables"):
        for table in data["tables"]:
            lines.append(f"MESA: {table.get('name', '')} SALA {table.get('living_room', {}).get('name', '')}")

    # Detalle
    lines.append(sep)
    lines.append("Cant x P.Unit        IMPORTE")
    lines.append("Descripcion")
    lines.append(sep)

    for prod in data.get("products", []):
        cantidad = float(prod["pivot"]["amount"])
        precio = float(prod["pivot"]["price"])
        subtotal = cantidad * precio
        tax = prod["pivot"].get("taxe", None)

        lines.append(f"{cantidad:.2f} x {precio:.2f}".ljust(20) + f"{subtotal:.2f}".rjust(10))
        if tax is not None and data.get("billing"):
            lines.append(f"IVA {tax}%")
        lines.append(prod.get("name", "").upper())

    lines.append(sep)
    lines.append(f"TOTAL: {float(data['total']):>23.2f}")
    lines.append(sep)

    if data.get("billing"):
        lines.append(f"CAE: {fields.get('cae', '---')}")
        lines.append(f"VTO: {fields.get('caef_ch_vto', '')}")
        lines.append("[QR OMITIDO PARA TERMINALES DE TEXTO]")  # Puedes usar una librería QR si deseas

    lines.append("\n" * 3)  # espacio para corte

    return "\n".join(lines)

def load_config():
    """Loads or prompts for initial config containing CUIT and device ID."""
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)

    cuit = input("🔐 Enter company CUIT: ").strip()
    device_id = os.uname().nodename if hasattr(os, 'uname') else platform.node()
    config = {"cuit": cuit, "device_id": device_id}

    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)

    print(f"[✓] Configuration saved in {CONFIG_FILE}")
    return config

def get_local_ip():
    """Returns the device's local IP address."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception as e:
        print(f"[X] Failed to get local IP: {e}")
        return None

def is_ip_open(ip, port=9100, timeout=0.3):
    """Checks if an IP and port is reachable."""
    try:
        with socket.socket() as sock:
            sock.settimeout(timeout)
            sock.connect((ip, port))
            return True
    except:
        return False

def scan_network_printers():
    """Scans the LAN for printers listening on port 9100."""
    base_ip = get_local_ip()
    if not base_ip:
        return []

    subnet = ".".join(base_ip.split(".")[:3]) + "."
    print(f"🌐 Scanning network {subnet}0/24 for printers...")
    results = []

    def worker(ip):
        if is_ip_open(ip):
            results.append({"name": f"Network Printer ({ip})", "identifier": ip, "type": "network"})

    threads = [threading.Thread(target=worker, args=(f"{subnet}{i}",)) for i in range(1, 255)]
    for t in threads: t.start()
    for t in threads: t.join()

    return results

def detect_local_printers():
    """Detects printers installed locally on Windows."""
    return [{"name": p[2], "identifier": p[2], "type": "local"} for p in win32print.EnumPrinters(2)]

def register_device_to_laravel(cuit, device_id, printers):
    """Sends printer/device data to the Laravel API."""
    payload = {"cuit": cuit, "device_id": device_id, "impresoras": printers}
    try:
        res = requests.post(LARAVEL_API_URL, json=payload)
        if res.status_code == 200:
            print("[✓] Device and printers registered successfully.")
        else:
            print(f"[X] Laravel error: {res.status_code} - {res.text}")
    except Exception as e:
        print(f"[X] Failed to connect to Laravel: {e}")

def print_invoice(data, destination):
    """Prints the invoice to a network or local printer."""
    try:
        print(f"[🖨️] Sending ticket to {destination}")
        content = generate_ticket_text(data).encode("utf-8")
        if destination.replace(".", "").isdigit():
            with socket.socket() as s:
                s.connect((destination, 9100))
                s.sendall(content)
            print(f"[🖨️] Sent via network to {destination}")
        else:
            hPrinter = win32print.OpenPrinter(destination)
            try:
                hJob = win32print.StartDocPrinter(hPrinter, 1, ("Factura", None, "RAW"))
                try:
                    win32print.StartPagePrinter(hPrinter)
                    win32print.WritePrinter(hPrinter, content)
                    win32print.EndPagePrinter(hPrinter)
                finally:
                    win32print.EndDocPrinter(hPrinter)
            finally:
                win32print.ClosePrinter(hPrinter)
            print(f"[🖨️] Sent to local printer: {destination}")
    except Exception as e:
        print(f"[X] Failed to print on {destination}: {e}")

def build_pusher_ws_url():
    """Builds the WebSocket URL for Pusher connection."""
    clusters = {
        "mt1": "ws.pusherapp.com",
        "us2": "ws-us2.pusher.com",
        "eu": "ws-eu.pusher.com",
        "ap1": "ws-ap1.pusher.com"
    }
    return f"wss://{clusters.get(PUSHER_CLUSTER, 'ws.pusherapp.com')}/app/{PUSHER_APP_KEY}?protocol=7&client=python"

def handle_pusher_message(ws, message, printers, cuit):
    """Handles WebSocket message from Pusher."""
    try:
        print(message)
        msg = json.loads(message)
        event = msg.get("event")
        expected_event = f"{EVENT_NAME}_{cuit}"

        if event == "pusher:connection_established":
            ws.send(json.dumps({"event": "pusher:subscribe", "data": {"channel": CHANNEL}}))
            print("[🔔] Subscribed to channel.")
        elif event == expected_event:
            payload = json.loads(msg["data"]) if isinstance(msg["data"], str) else msg["data"]
            invoice = payload.get("invoice")
            printer_address = payload.get("printer_address")
            if invoice:
                print_invoice(invoice, printer_address)
            elif printers:
                print_invoice(invoice, printers[0]['identifier'])
    except Exception as e:
        print(f"[X] Failed to process message: {e}")

def connect_to_pusher(printers, cuit):
    """Establishes WebSocket connection with Pusher."""
    url = build_pusher_ws_url()
    print(f"[🌐] Connecting to {url}...")

    ws = websocket.WebSocketApp(url,
        on_open=lambda ws: print("[✅] Connected to Pusher WebSocket."),
        on_message=lambda ws, msg: handle_pusher_message(ws, msg, printers, cuit),
        on_error=lambda ws, err: print("[X] WebSocket error:", err),
        on_close=lambda ws, code, msg: print("[X] WebSocket closed:", msg))

    threading.Thread(target=ws.run_forever, daemon=True).start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        ws.close()
        print("[⏹️] Listener stopped.")

def main():
    config = load_config()
    printers = scan_network_printers() + detect_local_printers()

    print(f"✅ Found {len(printers)} printers (network + local).")
    for i, p in enumerate(printers, 1):
        print(f"{i}. {p['name']} - {p['identifier']} ({p['type']})")

    register_device_to_laravel(config["cuit"], config["device_id"], printers)
    connect_to_pusher(printers, config["cuit"])

if __name__ == "__main__":
    main()