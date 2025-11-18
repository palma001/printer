from fastapi.routing import APIRouter

home_router = APIRouter()


@home_router.get("/", tags=["Home"])
async def read_home():
    return {"message": "Welcome to the Home Page"}
