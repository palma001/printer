from typing import Any

import httpx

from core.constants.env import EnvVariables


def register_device_to_api(
    cuit: str, deviceId: str, printers: list[dict[str, Any]]
) -> dict[str, Any]:
    if EnvVariables.api_url() is None:
        raise ValueError("API URL is not set")
    payload: dict[str, Any] = {
        "cuit": cuit,
        "deviceId": deviceId,
        "printers": printers,
    }
    response = httpx.post(
        EnvVariables.api_url(),
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=3,
    )
    if response.status_code >= 400:
        raise ConnectionError(f"Failed to register device: {response.status_code}")
    return response.json()
