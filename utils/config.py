import os
import json
import platform

CONFIG_FILE = "config.json"
CUIT_FILE = "cuit.txt"  # Nuevo: archivo que contiene el CUIT

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)

    # 🔐 Intentamos cargar el CUIT desde el archivo plano
    cuit = None
    if os.path.exists(CUIT_FILE):
        with open(CUIT_FILE, "r") as f:
            cuit = f.read().strip()

    # Si no hay cuit.txt o está vacío, usamos input (modo normal consola)
    if not cuit:
        try:
            cuit = input("🔐 Enter company CUIT: ").strip()
        except Exception:
            raise RuntimeError("[X] CUIT is missing and cannot be requested interactively (no console).")

    device_id = os.uname().nodename if hasattr(os, 'uname') else platform.node()
    config = {"cuit": cuit, "device_id": device_id}

    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)

    print(f"[✓] Configuration saved in {CONFIG_FILE}")
    return config
