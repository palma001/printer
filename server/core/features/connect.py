import json

from fastapi import WebSocket

from core.constants.doc import CUIT_FILE
from core.services.api import register_device_to_api
from core.services.api.websocket import connect_to_pusher
from core.services.printers import PrintersService
from core.state.app_state import AppStateObserver, AppStateType


async def connect_service(websocket: WebSocket, cuit: str | None) -> None:
    local_cuit = cuit
    if (
        AppStateType.ERROR != AppStateObserver.observer().value.event
        and AppStateObserver.observer().value.event != AppStateType.DISCONNECTED
    ):
        return
    AppStateObserver.add(AppStateType.CONNECTING, cuit=cuit)
    if local_cuit is None:
        with open(CUIT_FILE) as configFile:
            json_config = json.load(configFile)
            local_cuit = json_config["cuit"]
    else:
        with open(CUIT_FILE, "w") as configFile:
            json.dump({"cuit": local_cuit}, configFile)
    printers = PrintersService().getPrinters()
    register_device_to_api(
        cuit=local_cuit,
        printers=printers,
        deviceId=websocket.client.host if websocket.client is not None else "",
    )
    await connect_to_pusher(printers, local_cuit)
