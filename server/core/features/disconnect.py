from core.state.app_state import AppStateObserver, AppStateType


async def disconnect_service():
    """Disconnects the service and updates the state."""
    AppStateObserver.add(AppStateType.DISCONNECTED)
