from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=BACKEND_DIR / ".env", extra="ignore")

    database_url: str = "sqlite+aiosqlite:///" + (BACKEND_DIR / "local.db").as_posix()
    jwt_secret: str = Field(min_length=32)
    jwt_algorithm: str = "HS256"
    jwt_ttl_minutes: int = 60 * 24 * 30
    consent_version: str = "2026-10-v1"


@lru_cache
def get_settings() -> Settings:
    return Settings()
