"""User schemas."""

import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from kidneuro.models.user import UserRole


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=255)
    role: UserRole = UserRole.PARENT
    phone: str | None = None
    timezone: str = "UTC"
    locale: str = "en"


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    avatar_url: str | None = None
    timezone: str | None = None
    locale: str | None = None


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: UserRole
    is_active: bool
    is_verified: bool
    phone: str | None
    avatar_url: str | None
    timezone: str
    locale: str
    created_at: datetime
    last_login_at: datetime | None

    model_config = {"from_attributes": True}


class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int
    page: int
    per_page: int
