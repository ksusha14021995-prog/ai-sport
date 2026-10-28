from fastapi import APIRouter, FastAPI
from sqlalchemy import text

from app.api import auth, me
from app.api.deps import DbSession

app = FastAPI(title="AI-sport API", version="0.1.0")

api = APIRouter(prefix="/api/v1")


@api.get("/health", tags=["health"])
async def health(db: DbSession) -> dict[str, str]:
    await db.execute(text("SELECT 1"))
    return {"status": "ok"}


api.include_router(auth.router)
api.include_router(me.router)
app.include_router(api)
