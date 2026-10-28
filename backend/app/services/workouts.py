from collections import defaultdict
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import SetResult, WorkoutSession
from app.schemas.workout import ExerciseWeekProgress, WorkoutCreate


def as_utc(value: datetime) -> datetime:
    # SQLite hands back naive datetimes; everything is stored in UTC.
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def week_start(value: datetime) -> date:
    day = as_utc(value).date()
    return day - timedelta(days=day.weekday())


async def create_workout(db: AsyncSession, user_id: int, payload: WorkoutCreate) -> tuple[WorkoutSession, bool]:
    """Returns (workout, created). A repeated client_id returns the stored workout."""
    if payload.client_id is not None:
        existing = await db.scalar(
            select(WorkoutSession).where(
                WorkoutSession.user_id == user_id, WorkoutSession.client_id == payload.client_id
            )
        )
        if existing is not None:
            return existing, False

    workout = WorkoutSession(
        user_id=user_id,
        client_id=payload.client_id,
        plan_template_id=payload.plan_template_id,
        started_at=as_utc(payload.started_at),
        duration_seconds=payload.duration_seconds,
        perceived_difficulty=payload.perceived_difficulty,
        sets=[
            SetResult(position=position, **set_in.model_dump())
            for position, set_in in enumerate(payload.sets)
        ],
    )
    db.add(workout)
    await db.commit()
    await db.refresh(workout, attribute_names=["sets"])
    return workout, True


async def list_workouts(db: AsyncSession, user_id: int, limit: int) -> list[WorkoutSession]:
    result = await db.scalars(
        select(WorkoutSession)
        .where(WorkoutSession.user_id == user_id)
        .order_by(WorkoutSession.started_at.desc(), WorkoutSession.id.desc())
        .limit(limit)
    )
    return list(result)


async def weekly_progress(
    db: AsyncSession, user_id: int, weeks: int, today: date | None = None
) -> list[ExerciseWeekProgress]:
    # Aggregated in Python: the data per user is tiny and this keeps SQL portable
    # (date_trunc vs strftime) between Postgres and the SQLite test fallback.
    today = today or datetime.now(UTC).date()
    since = today - timedelta(days=today.weekday()) - timedelta(weeks=weeks - 1)
    rows = await db.execute(
        select(WorkoutSession.id, WorkoutSession.started_at, SetResult)
        .join(SetResult, SetResult.session_id == WorkoutSession.id)
        .where(
            WorkoutSession.user_id == user_id,
            WorkoutSession.started_at >= datetime.combine(since, datetime.min.time(), tzinfo=UTC),
        )
    )

    buckets: dict[tuple[str, date], dict] = defaultdict(
        lambda: {"sessions": set(), "sets": 0, "reps": 0, "clean": 0, "reps_with_clean": 0, "hold": 0, "errors": defaultdict(int)}
    )
    for session_id, started_at, set_result in rows:
        bucket = buckets[(set_result.exercise_id, week_start(started_at))]
        bucket["sessions"].add(session_id)
        bucket["sets"] += 1
        bucket["reps"] += set_result.reps or 0
        if set_result.clean_reps is not None:
            bucket["clean"] += set_result.clean_reps
            bucket["reps_with_clean"] += set_result.reps or 0
        bucket["hold"] += set_result.hold_seconds or 0
        for code, count in (set_result.errors or {}).items():
            bucket["errors"][code] += count

    return [
        ExerciseWeekProgress(
            exercise_id=exercise_id,
            week_start=week,
            sessions=len(b["sessions"]),
            sets=b["sets"],
            total_reps=b["reps"],
            clean_reps=b["clean"],
            clean_ratio=round(b["clean"] / b["reps_with_clean"], 3) if b["reps_with_clean"] else None,
            total_hold_seconds=b["hold"],
            total_errors=sum(b["errors"].values()),
            errors=dict(b["errors"]),
        )
        for (exercise_id, week), b in sorted(buckets.items(), key=lambda item: (item[0][1], item[0][0]))
    ]
