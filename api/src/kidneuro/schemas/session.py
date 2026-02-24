"""Therapy session schemas."""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from kidneuro.models.session import SessionStatus


class SessionCreate(BaseModel):
    child_id: uuid.UUID
    game_id: uuid.UUID
    game_config: dict | None = None


class SessionUpdate(BaseModel):
    status: SessionStatus | None = None
    score: int | None = None
    accuracy: float | None = Field(None, ge=0.0, le=1.0)
    avg_response_time_ms: int | None = None
    difficulty_level: int | None = Field(None, ge=1, le=10)
    metrics: dict | None = None
    notes: str | None = None


class SessionEventCreate(BaseModel):
    event_type: str = Field(max_length=50)
    data: dict[str, Any] | None = None


class SessionEventResponse(BaseModel):
    id: uuid.UUID
    event_type: str
    timestamp: datetime
    data: dict | None

    model_config = {"from_attributes": True}


class SessionResponse(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    game_id: uuid.UUID
    status: SessionStatus
    started_at: datetime
    ended_at: datetime | None
    duration_seconds: int | None
    pause_count: int
    score: int | None
    accuracy: float | None
    avg_response_time_ms: int | None
    difficulty_level: int
    metrics: dict | None
    game_config: dict | None
    notes: str | None

    model_config = {"from_attributes": True}


class SessionListResponse(BaseModel):
    items: list[SessionResponse]
    total: int
    page: int
    per_page: int
