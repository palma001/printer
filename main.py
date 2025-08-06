# main.py
from utils.config import load_config
from utils.network import scan_network_printers, detect_local_printers
from utils.api import register_device_to_laravel
from utils.websocket_handler import connect_to_pusher
import winreg
import winshell
import os
import sys
from win32com.client import Dispatch


def add_to_startup(app_name="OrderwisePrinter", exe_path=None):
    """
    Agrega el ejecutable al inicio de Windows usando el registro y un acceso directo en shell:startup.
    """
    if exe_path is None:
        exe_path = os.path.abspath(sys.argv[0])

    # --- 1. Registro en el inicio (por si acaso) ---
    try:
        key_path = r"Software\Microsoft\Windows\CurrentVersion\Run"
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_ALL_ACCESS) as key:
            try:
                current_value, _ = winreg.QueryValueEx(key, app_name)
                if current_value != exe_path:
                    winreg.SetValueEx(key, app_name, 0, winreg.REG_SZ, exe_path)
                    print("[✓] Agregado al inicio desde el registro.")
            except FileNotFoundError:
                winreg.SetValueEx(key, app_name, 0, winreg.REG_SZ, exe_path)
                print("[✓] Agregado al inicio desde el registro.")
    except Exception as e:
        print(f"[X] Error al agregar al registro: {e}")

    # --- 2. Crear acceso directo en carpeta de inicio ---
    try:
        startup_folder = winshell.startup()
        shortcut_path = os.path.join(startup_folder, f"{app_name}.lnk")

        if not os.path.exists(shortcut_path):
            shell = Dispatch("WScript.Shell")
            shortcut = shell.CreateShortCut(shortcut_path)
            shortcut.TargetPath = exe_path
            shortcut.WorkingDirectory = os.path.dirname(exe_path)
            shortcut.IconLocation = exe_path
            shortcut.save()
            print("[✓] Acceso directo creado en carpeta de inicio.")
    except Exception as e:
        print(f"[X] Error al crear acceso directo: {e}")


def main():
    add_to_startup()

    config = load_config()
    printers = scan_network_printers() + detect_local_printers()

    print(f"✅ Found {len(printers)} printers (network + local).")
    for i, p in enumerate(printers, 1):
        print(f"{i}. {p['name']} - {p['identifier']} ({p['type']})")

    register_device_to_laravel(config["cuit"], config["device_id"], printers)
    connect_to_pusher(printers, config["cuit"])

if __name__ == "__main__":
    main()
