"""Test DB: DATABASE_URL from the real environment (CI postgres), else a temp SQLite file."""
import os
import tempfile
from pathlib import Path

_TMP_DIR = Path(tempfile.mkdtemp(prefix="aisport-tests-"))
if not os.environ.get("DATABASE_URL"):
    os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///" + (_TMP_DIR / "test.db").as_posix()
os.environ.setdefault("JWT_SECRET", "test-secret-that-is-long-enough-for-hs256-0123456789")
os.environ.setdefault("CONSENT_VERSION", "2026-10-v1")

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402

import app.models  # noqa: E402,F401
from app.db import Base, engine  # noqa: E402
from app.main import app  # noqa: E402

CONSENT_VERSION = os.environ["CONSENT_VERSION"]


@pytest.fixture(scope="session", autouse=True)
async def schema():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture(autouse=True)
async def clean_tables(schema):
    yield
    async with engine.begin() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            await conn.execute(table.delete())


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as http:
        yield http


async def register(client: AsyncClient, email: str = "user@example.com", password: str = "s3cret-pass") -> str:
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "consent": {"accepted": True, "version": CONSENT_VERSION}},
    )
    assert response.status_code == 201, response.text
    return response.json()["access_token"]


@pytest.fixture
async def auth_headers(client) -> dict[str, str]:
    token = await register(client)
    return {"Authorization": f"Bearer {token}"}


PROFILE = {
    "goals": ["loseWeight", "tone"],
    "experience": "under6Months",
    "days_per_week": 3,
    "minutes_per_session": 30,
    "sex": "female",
    "age": 30,
    "height_cm": 168,
    "weight_kg": None,
    "screening_passed": True,
    "calibration": {
        "squat_reps": 15,
        "squat_errors": 2,
        "pushup_reps": 6,
        "pushup_variant": "knees",
        "plank_seconds": 40,
        "plank_errors": 1,
        "perceived_difficulty": 6,
    },
}

PLAN = {
    "template_id": "beginner-fullbody-v1",
    "title": "Начальный: всё тело",
    "level": "beginner",
    "weeks": 4,
    "sessions_per_week": 3,
    "minutes_per_session": 30,
    "starting_exercises": [
        {"exercise_id": "squat", "title": "Приседания", "sets": 3, "reps": 12},
        {"exercise_id": "plank", "title": "Планка", "sets": 3, "hold_seconds": 30},
    ],
}
