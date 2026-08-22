from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...core.deps import get_current_user
from ...core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from ...db import get_db
from ...models import User
from ...models.enums import UserRole
from ...schemas.common import ORMModel

router = APIRouter(prefix="/auth", tags=["auth"])


class TokenResponse(ORMModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserOut(ORMModel):
    id: object
    email: str
    display_name: str | None
    role: str
    preferred_language: str


class RegisterRequest(ORMModel):
    email: str
    password: str
    display_name: str | None = None


@router.post("/register", response_model=UserOut, status_code=201)
def register(body: RegisterRequest, db: Session = Depends(get_db)) -> User:
    existing = db.scalar(select(User).where(User.email == body.email))
    if existing is not None:
        raise HTTPException(409, "Email already registered")
    user = User(
        email=body.email,
        hashed_password=hash_password(body.password),
        display_name=body.display_name,
        role=UserRole.USER,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)) -> TokenResponse:
    user = db.scalar(select(User).where(User.email == form.username))
    if user is None or not verify_password(form.password, user.hashed_password):
        raise HTTPException(401, "Incorrect email or password")
    user.last_login_at = datetime.now(UTC)
    db.commit()
    return TokenResponse(
        access_token=create_access_token(str(user.id), user.role.value),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)) -> User:
    return user
