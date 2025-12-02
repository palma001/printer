from core.state.app_state import AppStateObserver, AppStateType


async def disconnect_service():
    """Disconnects the service and updates the state."""
    websocket = AppStateObserver.websocket
    websocket_pusher = AppStateObserver.websocket_pusher
    AppStateObserver.add(AppStateType.DISCONNECTED)
    if websocket is not None:
        await websocket.close()
        AppStateObserver.websocket = None
    if websocket_pusher is not None:
        await websocket_pusher.close()
        AppStateObserver.websocket_pusher = None
