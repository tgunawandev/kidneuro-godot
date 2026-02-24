"""Difficulty recommendation endpoints."""

import uuid

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user
from kidneuro.models.user import User
from kidneuro.services.difficulty import DifficultyEngine

router = APIRouter()


# ---------------------------------------------------------------------------
# Response schema
# ---------------------------------------------------------------------------


class DifficultyMetrics(BaseModel):
    avg_accuracy: float
    accuracy_trend: float
    rt_trend: float
    composite_score: float
    sessions_analyzed: int
    sensitivity: float


class DifficultyResponse(BaseModel):
    recommended_level: int
    current_level: int | None = None
    confidence: float
    reasoning: str
    metrics: dict


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.get("/children/{child_id}/games/{game_id}", response_model=DifficultyResponse)
async def get_recommended_difficulty(
    child_id: uuid.UUID,
    game_id: uuid.UUID,
    lookback: int = Query(10, ge=1, le=50, description="Number of recent sessions to analyze"),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Get recommended difficulty level for a child playing a specific game.

    The adaptive engine analyses the child's recent completed sessions and
    returns a difficulty recommendation (1-10) along with a confidence score
    and human-readable reasoning.
    """
    return await DifficultyEngine.recommend(
        db, child_id, game_id, lookback_sessions=lookback
    )
