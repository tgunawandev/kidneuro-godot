"""Telemetry endpoints - receives game telemetry from Godot client."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user
from kidneuro.models.session import SessionEvent, TherapySession
from kidneuro.models.user import User

router = APIRouter()


# ---------------------------------------------------------------------------
# Request / Response schemas
# ---------------------------------------------------------------------------


class TelemetryEvent(BaseModel):
    session_id: uuid.UUID
    game_type: str = Field(max_length=50)
    level: int = Field(ge=1, le=10)
    success_rate: float = Field(ge=0.0, le=1.0)
    reaction_time_ms: int = Field(ge=0)
    event_data: dict | None = None


class TelemetryBatch(BaseModel):
    events: list[TelemetryEvent] = Field(max_length=100)


class TelemetryResponse(BaseModel):
    received: int
    processed: int


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.post("/event", response_model=TelemetryResponse, status_code=status.HTTP_201_CREATED)
async def record_telemetry(
    payload: TelemetryEvent,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Record a single telemetry event from the game client."""
    result = await db.execute(
        select(TherapySession).where(TherapySession.id == payload.session_id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    event = SessionEvent(
        session_id=payload.session_id,
        event_type="telemetry",
        data={
            "game_type": payload.game_type,
            "level": payload.level,
            "success_rate": payload.success_rate,
            "reaction_time_ms": payload.reaction_time_ms,
            **(payload.event_data or {}),
        },
    )
    db.add(event)

    # Update session rolling metrics
    session.accuracy = payload.success_rate
    session.avg_response_time_ms = payload.reaction_time_ms
    session.difficulty_level = payload.level

    await db.flush()
    return {"received": 1, "processed": 1}


@router.post("/batch", response_model=TelemetryResponse, status_code=status.HTTP_201_CREATED)
async def record_telemetry_batch(
    payload: TelemetryBatch,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Record a batch of telemetry events (for offline sync)."""
    processed = 0
    for evt in payload.events:
        result = await db.execute(
            select(TherapySession).where(TherapySession.id == evt.session_id)
        )
        session = result.scalar_one_or_none()
        if not session:
            continue

        event = SessionEvent(
            session_id=evt.session_id,
            event_type="telemetry",
            data={
                "game_type": evt.game_type,
                "level": evt.level,
                "success_rate": evt.success_rate,
                "reaction_time_ms": evt.reaction_time_ms,
                **(evt.event_data or {}),
            },
        )
        db.add(event)

        session.accuracy = evt.success_rate
        session.avg_response_time_ms = evt.reaction_time_ms
        session.difficulty_level = evt.level
        processed += 1

    await db.flush()
    return {"received": len(payload.events), "processed": processed}
