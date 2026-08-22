"""Shared FastAPI dependencies: current user + role-based access control."""

from __future__ import annotations

import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jwt import PyJWTError
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import User
from ..models.enums import UserRole
from .security import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)

_ROLE_RANK = {
    UserRole.USER: 0,
    UserRole.PREMIUM: 1,
    UserRole.ANALYST: 2,
    UserRole.EDITOR: 3,
    UserRole.ADMINISTRATOR: 4,
}


def get_current_user(
    token: str | None = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> User:
    unauthorized = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    if token is None:
        raise unauthorized
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise unauthorized
        user_id = uuid.UUID(payload["sub"])
    except (PyJWTError, KeyError, ValueError) as exc:
        raise unauthorized from exc

    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise unauthorized
    return user


def require_role(minimum_role: UserRole):
    def _checker(user: User = Depends(get_current_user)) -> User:
        if _ROLE_RANK[user.role] < _ROLE_RANK[minimum_role]:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Insufficient role")
        return user

    return _checker
