import asyncio
import json
import multiprocessing
import re
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


def add_to_windows_startup():
    """Add this script to Windows startup by creating a batch file in the Startup folder."""
    import os
    import platform

    if (
        re.match(pattern=r"windows", string=platform.system(), flags=re.IGNORECASE)
        is None
    ):
        print("This function is only for Windows.")
        return
    script_path = os.path.abspath(__file__)
    startup_path = (
        os.path.expanduser("~")
        + r"\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    # Ensure startup directory exists
    os.makedirs(startup_path, exist_ok=True)

    batch_content = f'@echo off\nstart /b python "{script_path}"\n'
    batch_file = os.path.join(startup_path, "server_startup.bat")

    try:
        with open(batch_file, "w") as f:
            f.write(batch_content)
        print(f"Added to startup: {batch_file}")
    except Exception as e:
        print(f"Failed to add to startup: {e}")


def main() -> None:
    if EnvVariables.environment() == "dev":
        webbrowser.open(f"http://{EnvVariables.host()}:{EnvVariables.port()}/docs")
    multiprocessing.freeze_support()
    run("server:app", host=EnvVariables.host(), port=EnvVariables.port(), reload=True)


if __name__ == "__main__":
    # Add to pc start up process
    main()
