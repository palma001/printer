import asyncio
import json

from fastapi import WebSocket, WebSocketDisconnect
from fastapi.routing import APIRouter

from core.features.connect import connect_service
from core.features.disconnect import disconnect_service
from core.state.app_state import AppStateObserver
from core.state.events import ChannelEventsType

ws_router = APIRouter()


@ws_router.websocket("/ws")
async def websocket_endpoint(webSocket: WebSocket):
    await webSocket.accept()
    try:
        while True:
            AppStateObserver.websocket = webSocket
            data = await webSocket.receive_text()
            data_json: dict = json.loads(data)
            print(f">> Event received {data_json}")
            match data_json["event"]:
                case ChannelEventsType.CONNECTED | ChannelEventsType.CONNECTING:
                    asyncio.create_task(
                        connect_service(
                            webSocket,
                            data_json["payload"]["cuit"]
                            if data_json["payload"]["cuit"] is not None
                            else None,
                        )
                    )
                case ChannelEventsType.DISCONNECTED:
                    await disconnect_service()
                case ChannelEventsType.GET_CURRENT_STATUS:
                    await webSocket.send_text(
                        json.dumps(AppStateObserver.observer().value.dict())
                    )
                case _:
                    await webSocket.send_text("Unknown event")
    except WebSocketDisconnect:
        print("Client disconnected")
        print("Test1")
    except Exception as e:
        print(f"Test2 {e}")
