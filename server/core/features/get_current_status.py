import json

from fastapi import WebSocket

from core.state.app_state import AppStateObserver
from core.state.events import ChannelEventsType


async def get_current_status(websocket: WebSocket):
    """Returns the current status of the application."""
    return await websocket.send_text(
        json.dumps(
            {
                "event": ChannelEventsType.GET_CURRENT_STATUS.value,
                "payload": AppStateObserver.observer().value.event,
            }
        )
    )
