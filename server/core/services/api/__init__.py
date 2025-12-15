from typing import Any

import httpx

from core.constants.env import EnvVariables
from core.state.app_state import AppStateObserver, AppStateType


def register_device_to_api(
    cuit: str, deviceId: str, printers: list[dict[str, Any]]
) -> dict[str, Any]:
    if EnvVariables.api_url() is None:
        raise ValueError("API URL is not set")
    payload: dict[str, Any] = {
        "cuit": cuit,
        "deviceId": deviceId,
        # TODO: fix printer model 
        "printers": printers,
    }
    response = httpx.post(
        EnvVariables.api_url(),
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=3,
    )
    if response.status_code >= 400:
        AppStateObserver.add(state=AppStateType.ERROR, message=f"Error sending from {deviceId} and company {cuit} payload {payload}, exited with code {response.status_code}")
        return {}
    return response.json()
