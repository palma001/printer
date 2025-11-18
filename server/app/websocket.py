import asyncio

from fastapi import WebSocket, WebSocketDisconnect
from fastapi.routing import APIRouter

ws_router = APIRouter()


@ws_router.websocket("/ws")
async def websocket_endpoint(webSocket: WebSocket):
    await webSocket.accept()
    try:
        while True:
            data = await webSocket.receive_text()
            if data.lower() == "get_printers":
                await asyncio.sleep(1)  # Simulate async operation
                printers = ["Printer_A", "Printer_B", "Printer_C"]
                await webSocket.send_text(f"Available Printers: {printers}")
            else:
                await webSocket.send_text(f"Message text was: {data}")

    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception:
        await webSocket.close()
