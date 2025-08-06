import requests

LARAVEL_API_URL = "http://localhost:8000/api/public/register-device"
# LARAVEL_API_URL = "https://api-orderwise.qbitsinc.com/api/public/register-device"

def register_device_to_laravel(cuit, device_id, printers):
    payload = {"cuit": cuit, "device_id": device_id, "printers": printers}
    try:
        res = requests.post(LARAVEL_API_URL, json=payload)
        if res.status_code == 200:
            print("[✓] Device and printers registered successfully.")
        else:
            print(f"[X] Laravel error: {res.status_code} - {res.text}")
    except Exception as e:
        print(f"[X] Failed to connect to Laravel: {e}")
