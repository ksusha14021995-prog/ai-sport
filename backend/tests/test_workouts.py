import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select

from app.db import SessionLocal
from app.models import OnboardingProfile, SetResult, TrainingPlan, User, WorkoutSession
from tests.conftest import PLAN, PROFILE, register


def workout_payload(started_at: datetime, **overrides) -> dict:
    return {
        "started_at": started_at.isoformat(),
        "duration_seconds": 1500,
        "perceived_difficulty": 7,
        "plan_template_id": "beginner-fullbody-v1",
        "sets": [
            {"exercise_id": "squat", "reps": 12, "clean_reps": 10, "errors": {"knees_inward": 2}, "duration_seconds": 45},
            {"exercise_id": "squat", "reps": 10, "clean_reps": 9, "errors": {"knees_inward": 1, "shallow": 1}, "duration_seconds": 40},
            {"exercise_id": "plank", "hold_seconds": 30, "errors": {"hips_high": 1}, "duration_seconds": 30},
        ],
        **overrides,
    }


async def test_workout_save_and_list(client, auth_headers):
    now = datetime.now(UTC)
    first = await client.post("/api/v1/me/workouts", json=workout_payload(now - timedelta(days=1)), headers=auth_headers)
    assert first.status_code == 201, first.text
    second = await client.post("/api/v1/me/workouts", json=workout_payload(now), headers=auth_headers)
    assert second.status_code == 201

    listed = await client.get("/api/v1/me/workouts", params={"limit": 1}, headers=auth_headers)
    assert listed.status_code == 200
    items = listed.json()
    assert len(items) == 1
    assert items[0]["id"] == second.json()["id"]
    assert [s["exercise_id"] for s in items[0]["sets"]] == ["squat", "squat", "plank"]
    assert items[0]["sets"][0]["errors"] == {"knees_inward": 2}


async def test_workout_retry_with_client_id_is_idempotent(client, auth_headers):
    payload = workout_payload(datetime.now(UTC), client_id=str(uuid.uuid4()))
    first = await client.post("/api/v1/me/workouts", json=payload, headers=auth_headers)
    retry = await client.post("/api/v1/me/workouts", json=payload, headers=auth_headers)
    assert (first.status_code, retry.status_code) == (201, 200)
    assert first.json()["id"] == retry.json()["id"]


async def test_workout_rejects_bad_sets_and_raw_pose_data(client, auth_headers):
    now = datetime.now(UTC)
    too_clean = workout_payload(now, sets=[{"exercise_id": "squat", "reps": 5, "clean_reps": 6, "duration_seconds": 10}])
    landmarks = workout_payload(now, sets=[{"exercise_id": "squat", "reps": 5, "duration_seconds": 10, "landmarks": [[0.1, 0.2]]}])
    naive_time = workout_payload(now.replace(tzinfo=None))
    for payload in (too_clean, landmarks, naive_time):
        assert (await client.post("/api/v1/me/workouts", json=payload, headers=auth_headers)).status_code == 422


async def test_progress_aggregates_per_exercise_per_week(client, auth_headers):
    now = datetime.now(UTC)
    this_monday = (now - timedelta(days=now.weekday())).replace(hour=10, minute=0, second=0, microsecond=0)
    last_week = this_monday - timedelta(days=7)
    for started_at in (this_monday, this_monday + timedelta(hours=1), last_week):
        await client.post("/api/v1/me/workouts", json=workout_payload(started_at), headers=auth_headers)
    # Outside the requested window.
    await client.post("/api/v1/me/workouts", json=workout_payload(this_monday - timedelta(weeks=5)), headers=auth_headers)

    response = await client.get("/api/v1/me/progress", params={"weeks": 2}, headers=auth_headers)
    assert response.status_code == 200, response.text
    items = {(i["exercise_id"], i["week_start"]): i for i in response.json()["items"]}
    assert len(items) == 4

    squat_now = items[("squat", this_monday.date().isoformat())]
    assert squat_now["sessions"] == 2
    assert squat_now["sets"] == 4
    assert squat_now["total_reps"] == 44
    assert squat_now["clean_reps"] == 38
    assert squat_now["clean_ratio"] == round(38 / 44, 3)
    assert squat_now["errors"] == {"knees_inward": 6, "shallow": 2}
    assert squat_now["total_errors"] == 8

    plank_last = items[("plank", last_week.date().isoformat())]
    assert plank_last["sessions"] == 1
    assert plank_last["total_hold_seconds"] == 30
    assert plank_last["clean_ratio"] is None


async def test_progress_is_per_user(client, auth_headers):
    await client.post("/api/v1/me/workouts", json=workout_payload(datetime.now(UTC)), headers=auth_headers)
    other = {"Authorization": f"Bearer {await register(client, email='other@example.com')}"}
    assert (await client.get("/api/v1/me/progress", headers=other)).json()["items"] == []
    assert (await client.get("/api/v1/me/workouts", headers=other)).json() == []


async def test_delete_account_cascades(client, auth_headers):
    await client.put("/api/v1/me/profile", json=PROFILE, headers=auth_headers)
    await client.put("/api/v1/me/plan", json=PLAN, headers=auth_headers)
    await client.post("/api/v1/me/workouts", json=workout_payload(datetime.now(UTC)), headers=auth_headers)
    other_token = await register(client, email="keep@example.com")
    await client.post(
        "/api/v1/me/workouts", json=workout_payload(datetime.now(UTC)), headers={"Authorization": f"Bearer {other_token}"}
    )

    response = await client.delete("/api/v1/me", headers=auth_headers)
    assert response.status_code == 204
    assert (await client.get("/api/v1/me", headers=auth_headers)).status_code == 401

    async with SessionLocal() as db:
        counts = {
            model.__name__: await db.scalar(select(func.count()).select_from(model))
            for model in (User, OnboardingProfile, TrainingPlan, WorkoutSession, SetResult)
        }
    assert counts == {"User": 1, "OnboardingProfile": 0, "TrainingPlan": 0, "WorkoutSession": 1, "SetResult": 3}

    login = await client.post("/api/v1/auth/login", json={"email": "user@example.com", "password": "s3cret-pass"})
    assert login.status_code == 401
