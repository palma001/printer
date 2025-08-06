import socket
import threading
import win32print

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return None

def is_ip_open(ip, port=9100, timeout=0.3):
    try:
        with socket.socket() as sock:
            sock.settimeout(timeout)
            sock.connect((ip, port))
            return True
    except:
        return False

def scan_network_printers():
    base_ip = get_local_ip()
    if not base_ip:
        return []

    subnet = ".".join(base_ip.split(".")[:3]) + "."
    results = []

    def worker(ip):
        if is_ip_open(ip):
            results.append({"name": f"Network Printer ({ip})", "identifier": ip, "type": "network"})

    threads = [threading.Thread(target=worker, args=(f"{subnet}{i}",)) for i in range(1, 255)]
    for t in threads: t.start()
    for t in threads: t.join()

    return results

def detect_local_printers():
    return [{"name": p[2], "identifier": p[2], "type": "local"} for p in win32print.EnumPrinters(2)]


