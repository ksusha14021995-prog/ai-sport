from datetime import UTC, datetime

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User
from app.schemas.auth import RegisterRequest
from app.services.security import hash_password, verify_password


class EmailTakenError(Exception):
    pass


async def register_user(db: AsyncSession, payload: RegisterRequest) -> User:
    user = User(
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        consent_version=payload.consent.version,
        consent_accepted_at=datetime.now(UTC),
    )
    db.add(user)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise EmailTakenError from exc
    await db.refresh(user)
    return user


async def authenticate(db: AsyncSession, email: str, password: str) -> User | None:
    user = await db.scalar(select(User).where(User.email == email.lower()))
    if not verify_password(password, user.password_hash if user else None):
        return None
    return user


async def delete_user(db: AsyncSession, user_id: int) -> None:
    # Profile, plan, workouts and sets go with it via ON DELETE CASCADE.
    await db.execute(delete(User).where(User.id == user_id))
    await db.commit()
