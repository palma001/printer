import webbrowser

from anyio import Path
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.concurrency import asynccontextmanager
from uvicorn import run

from app.home import home_router
from app.websocket import ws_router
from core.constants.env import EnvVariables
from core.state.app_state import AppStateObserver

load_dotenv(Path(__file__).parent / ".env")


@asynccontextmanager
async def lifespan(app: FastAPI):
    AppStateObserver()
    yield


app = FastAPI(lifespan=lifespan)


app.include_router(home_router)
app.include_router(ws_router)


def main() -> None:
    if EnvVariables.environment() == "dev":
        webbrowser.open(f"http://{EnvVariables.host()}:{EnvVariables.port()}/docs")
    run("server:app", host=EnvVariables.host(), port=EnvVariables.port(), reload=True)


if __name__ == "__main__":
    main()
