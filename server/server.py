import asyncio
import json
import multiprocessing
import webbrowser

from anyio import Path
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.concurrency import asynccontextmanager
from uvicorn import run

from app.home import home_router
from app.websocket import ws_router
from core.constants.doc import CUIT_FILE
from core.constants.env import EnvVariables
from core.features.connect import connect_service
from core.state.app_state import AppStateObserver, AppStateType

load_dotenv(Path(__file__).parent / ".env")


@asynccontextmanager
async def lifespan(app: FastAPI):
    AppStateObserver.subscribe(on_error=lambda x: print(f">>>> Error: f{x}"))
    with open(CUIT_FILE, "r") as configFile:
        try:
            json_config = json.loads(configFile.read())
            if json_config["cuit"] is not None and len(json_config["cuit"]) > 0:
                print(f">> Auto connecting at start {json_config['cuit']}")
                asyncio.create_task(connect_service(None, json_config["cuit"]))
        except Exception:
            AppStateObserver.add(state=AppStateType.DISCONNECTED)
    yield


app = FastAPI(lifespan=lifespan)


app.include_router(home_router)
app.include_router(ws_router)


def main() -> None:
    if EnvVariables.environment() == "dev":
        webbrowser.open(f"http://{EnvVariables.host()}:{EnvVariables.port()}/docs")
    multiprocessing.freeze_support()
    run("server:app", host=EnvVariables.host(), port=EnvVariables.port(), reload=True)


if __name__ == "__main__":
    main()
