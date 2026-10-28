from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession
from app.config import get_settings
from app.schemas.auth import LoginRequest, RegisterRequest, RegisterResponse, TokenResponse, UserRead
from app.services import users
from app.services.security import create_access_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: DbSession) -> RegisterResponse:
    current_version = get_settings().consent_version
    if payload.consent.version != current_version:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=f"Consent version must be {current_version}",
        )
    try:
        user = await users.register_user(db, payload)
    except users.EmailTakenError:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="Email already registered")
    token, expires_in = create_access_token(user.id)
    return RegisterResponse(access_token=token, expires_in=expires_in, user=UserRead.model_validate(user))


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, db: DbSession) -> TokenResponse:
    user = await users.authenticate(db, payload.email, payload.password)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    token, expires_in = create_access_token(user.id)
    return TokenResponse(access_token=token, expires_in=expires_in)
