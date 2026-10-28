from sqlalchemy import select

from app.db import SessionLocal
from app.models import OnboardingProfile
from tests.conftest import PLAN, PROFILE


async def test_profile_upsert(client, auth_headers):
    assert (await client.get("/api/v1/me/profile", headers=auth_headers)).status_code == 404

    created = await client.put("/api/v1/me/profile", json=PROFILE, headers=auth_headers)
    assert created.status_code == 200, created.text
    body = created.json()
    assert body["goals"] == ["loseWeight", "tone"]
    assert body["screening_passed"] is True
    passed_at = body["screening_passed_at"]

    updated = await client.put("/api/v1/me/profile", json={**PROFILE, "weight_kg": 61.5, "days_per_week": 4}, headers=auth_headers)
    assert updated.status_code == 200
    assert updated.json()["weight_kg"] == 61.5
    assert updated.json()["days_per_week"] == 4
    assert updated.json()["screening_passed_at"] == passed_at

    fetched = await client.get("/api/v1/me/profile", headers=auth_headers)
    assert fetched.json()["calibration"]["pushup_variant"] == "knees"


async def test_screening_answers_are_rejected(client, auth_headers):
    payload = {**PROFILE, "screening_answers": [False] * 9}
    response = await client.put("/api/v1/me/profile", json=payload, headers=auth_headers)
    assert response.status_code == 422

    async with SessionLocal() as db:
        assert (await db.scalars(select(OnboardingProfile))).all() == []


async def test_failed_screening_is_not_stored(client, auth_headers):
    response = await client.put("/api/v1/me/profile", json={**PROFILE, "screening_passed": False}, headers=auth_headers)
    assert response.status_code == 422


async def test_profile_validation(client, auth_headers):
    for override in ({"age": 17}, {"days_per_week": 6}, {"minutes_per_session": 20}, {"goals": []}, {"goals": ["fly"]}):
        response = await client.put("/api/v1/me/profile", json={**PROFILE, **override}, headers=auth_headers)
        assert response.status_code == 422, override


async def test_plan_requires_profile_then_upserts(client, auth_headers):
    assert (await client.put("/api/v1/me/plan", json=PLAN, headers=auth_headers)).status_code == 409

    await client.put("/api/v1/me/profile", json=PROFILE, headers=auth_headers)
    response = await client.put("/api/v1/me/plan", json=PLAN, headers=auth_headers)
    assert response.status_code == 200, response.text
    assert response.json()["starting_exercises"][1]["hold_seconds"] == 30

    replaced = await client.put("/api/v1/me/plan", json={**PLAN, "level": "intermediate", "weeks": 6}, headers=auth_headers)
    assert replaced.json()["level"] == "intermediate"
    assert (await client.get("/api/v1/me/plan", headers=auth_headers)).json()["weeks"] == 6


async def test_plan_exercise_needs_reps_or_hold(client, auth_headers):
    await client.put("/api/v1/me/profile", json=PROFILE, headers=auth_headers)
    bad = {**PLAN, "starting_exercises": [{"exercise_id": "squat", "title": "Приседания", "sets": 3, "reps": 10, "hold_seconds": 5}]}
    assert (await client.put("/api/v1/me/plan", json=bad, headers=auth_headers)).status_code == 422
