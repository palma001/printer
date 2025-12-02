import asyncio
import json
from enum import Enum
from typing import Callable

import reactivex.operators as opx
from fastapi import WebSocket
from pydantic.dataclasses import dataclass
from reactivex.subject import BehaviorSubject
from websockets import ClientConnection

from core.constants.doc import CUIT_FILE


class AppStateType(Enum):
    PRINTING = "printing"
    ERROR = "error"
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    SENDING_PRINTERS = "sending_printers"
    RECEIVING = "receiving"
    CONNECTING = "connecting"


@dataclass
class AppState:
    event: AppStateType
    cuit: str
    message: str = ""

    def dict(self):
        return {
            "event": self.event.value,
            "cuit": self.cuit,
            "message": self.message,
        }


class AppStateObserver:
    _instance: "AppStateObserver | None" = None
    websocket: WebSocket | None = None
    websocket_pusher: ClientConnection | None = None

    def __new__(cls) -> "AppStateObserver":
        if cls._instance is None:
            cls._instance = super(AppStateObserver, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if "_observer" not in self.__dict__:
            self._observer: BehaviorSubject[AppState] = BehaviorSubject(
                AppState(event=AppStateType.DISCONNECTED, cuit="")
            )

    @staticmethod
    def observer() -> BehaviorSubject[AppState]:
        return AppStateObserver()._observer

    @staticmethod
    def add(
        state: AppStateType, message="", cuit: str | None = None
    ) -> "AppStateObserver":
        instance = AppStateObserver()
        instance._observer.on_next(
            AppState(
                event=state,
                cuit=cuit if cuit is not None else instance._observer.value.cuit,
                message=message,
            )
        )
        return instance

    @staticmethod
    def map_add(mapper: Callable[[AppState], AppState]) -> "AppStateObserver":
        instance = AppStateObserver()
        instance._observer.on_next(mapper(instance._observer.value))
        return instance

    @staticmethod
    def subscribe(
        on_next: Callable[[AppState], None] | None = None,
        on_error: Callable[[Exception], None] | None = None,
        on_completed: Callable[[], None] | None = None,
    ):
        instance = AppStateObserver()

        def write_on_socket(state: AppState):
            websocket = AppStateObserver.websocket
            if websocket is not None:
                asyncio.create_task(websocket.send_text(json.dumps(state.dict())))

        def disconnect_websocket(state: AppState):
            with open(CUIT_FILE, "r") as configFile:
                json_cconfig = json.loads(configFile.read())
                write_on_socket(
                    AppState(
                        event=state.event,
                        cuit=json_cconfig["cuit"],
                        message=state.message,
                    )
                )

        def handle_event(state: AppState):
            match state.event:
                case AppStateType.DISCONNECTED | AppStateType.ERROR:
                    disconnect_websocket(state)
                case _:
                    write_on_socket(state)

        return instance._observer.pipe(opx.do_action(handle_event)).subscribe(
            on_next=on_next, on_error=on_error, on_completed=on_completed
        )
