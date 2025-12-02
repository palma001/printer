from enum import Enum
from typing import Any

from pydantic.dataclasses import dataclass


class ChannelEventsType(Enum):
    GET_CURRENT_STATUS = "get_current_status"
    PRINTING = "printing"
    ERROR = "error"
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    SENDING_PRINTERS = "sending_printers"
    RECEIVING = "receiving"
    CONNECTING = "connecting"

    def __eq__(self, value: object) -> bool:
        if isinstance(value, str):
            return self.value == value
        return super().__eq__(value)


@dataclass
class ChannelEvent:
    event: ChannelEventsType
    payload: dict[str, Any] | None
