import json
from typing import Any

import websockets

from core.constants.env import EnvVariables
from core.services.printer import print_invoice
from core.state.app_state import AppStateObserver, AppStateType


def build_pusher_ws_url() -> str:
    """Constructs the Pusher WebSocket URL."""
    clusters = {
        "mt1": "ws.pusherapp.com",
        "us2": "ws-us2.pusher.com",
        "eu": "ws-eu.pusher.com",
        "ap1": "ws-ap1.pusher.com",
    }
    cluster_host = clusters.get(EnvVariables.pusher_cluster(), "ws.pusherapp.com")
    return f"wss://{cluster_host}/app/{EnvVariables.pusher_app_key()}?protocol=7&client=python"


async def handle_pusher_message(
    channel: websockets.ClientConnection,
    message: str,
    cuit: str,
    printers: list[dict[str, Any]],
) -> None:
    """Handles incoming Pusher messages."""
    AppStateObserver.websocket_pusher = channel
    try:
        AppStateObserver.add(AppStateType.CONNECTED)
        msg = json.loads(message)
        event = msg["event"]
        if event == "pusher:connection_established":
            await channel.send(
                json.dumps(
                    {"event": "pusher:subscribe", "data": {"channel": "comandas"}}
                )
            )
        elif event == f"{EnvVariables.event_name()}_{cuit}":
            AppStateObserver.add(
                AppStateType.RECEIVING, message=f"Receiving from {cuit}"
            )
            payload = (
                json.loads(msg["data"]) if isinstance(msg["data"], str) else msg["data"]
            )
            invoice = payload["invoice"]
            printer = payload["printer"]
            printer_size = (
                int(printer["size"])
                if printer and printer["size"] is not None
                else EnvVariables.receipt_ticket_paper_size()
            )
            doc_type = payload["type"]

            if invoice and printer:
                await print_invoice(invoice, printer["name"], doc_type, printer_size)
            elif invoice and printers:
                await print_invoice(
                    invoice, printers[0]["identifier"], doc_type, printer_size
                )

    except Exception as e:
        # Depending on the desired behavior, you might want to re-raise the exception
        AppStateObserver.add(
            AppStateType.ERROR, message=f"Error handling Pusher message: {e}"
        )


async def connect_to_pusher(printers: list[dict[str, Any]], cuit: str) -> None:
    """Connects to Pusher WebSocket and listens for messages."""
    url = build_pusher_ws_url()
    async with websockets.connect(url) as websocket:
        async for message in websocket:
            await handle_pusher_message(
                websocket,
                message
                if isinstance(message, str)
                else message.decode("utf-8")
                if isinstance(message, bytes) or isinstance(message, bytearray)
                else "",
                cuit,
                printers,
            )
