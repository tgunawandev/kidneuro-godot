"""Analytics endpoints - therapy progress and insights."""

import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user
from kidneuro.models.child import Child
from kidneuro.models.session import SessionStatus, TherapySession
from kidneuro.models.user import User, UserRole

router = APIRouter()


class ChildProgress(BaseModel):
    child_id: uuid.UUID
    total_sessions: int
    completed_sessions: int
    total_play_time_minutes: int
    avg_accuracy: float | None
    avg_score: float | None
    sessions_this_week: int
    improvement_trend: float | None  # positive = improving


class DailyActivity(BaseModel):
    date: date
    sessions: int
    total_minutes: int
    avg_accuracy: float | None


@router.get("/children/{child_id}/progress", response_model=ChildProgress)
async def get_child_progress(
    child_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    if current_user.role == UserRole.PARENT:
        child_check = await db.execute(select(Child).where(Child.id == child_id, Child.parent_id == current_user.id))
        if not child_check.scalar_one_or_none():
            return {"child_id": child_id, "total_sessions": 0, "completed_sessions": 0,
                    "total_play_time_minutes": 0, "avg_accuracy": None, "avg_score": None,
                    "sessions_this_week": 0, "improvement_trend": None}

    base = select(TherapySession).where(TherapySession.child_id == child_id)

    total = (await db.execute(select(func.count()).select_from(base.subquery()))).scalar() or 0

    completed_q = base.where(TherapySession.status == SessionStatus.COMPLETED)
    completed = (await db.execute(select(func.count()).select_from(completed_q.subquery()))).scalar() or 0

    time_result = await db.execute(
        select(func.sum(TherapySession.duration_seconds)).where(TherapySession.child_id == child_id)
    )
    total_seconds = time_result.scalar() or 0

    acc_result = await db.execute(
        select(func.avg(TherapySession.accuracy)).where(
            TherapySession.child_id == child_id, TherapySession.accuracy.isnot(None)
        )
    )
    avg_accuracy = acc_result.scalar()

    score_result = await db.execute(
        select(func.avg(TherapySession.score)).where(
            TherapySession.child_id == child_id, TherapySession.score.isnot(None)
        )
    )
    avg_score = score_result.scalar()

    week_ago = date.today() - timedelta(days=7)
    week_result = await db.execute(
        select(func.count()).where(
            and_(TherapySession.child_id == child_id, func.date(TherapySession.started_at) >= week_ago)
        )
    )
    sessions_this_week = week_result.scalar() or 0

    return {
        "child_id": child_id,
        "total_sessions": total,
        "completed_sessions": completed,
        "total_play_time_minutes": total_seconds // 60,
        "avg_accuracy": round(float(avg_accuracy), 3) if avg_accuracy else None,
        "avg_score": round(float(avg_score), 1) if avg_score else None,
        "sessions_this_week": sessions_this_week,
        "improvement_trend": None,  # TODO: calculate from recent vs older sessions
    }


@router.get("/children/{child_id}/daily", response_model=list[DailyActivity])
async def get_daily_activity(
    child_id: uuid.UUID,
    days: int = Query(30, ge=1, le=365),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[dict]:
    since = date.today() - timedelta(days=days)

    result = await db.execute(
        select(
            func.date(TherapySession.started_at).label("date"),
            func.count().label("sessions"),
            func.sum(TherapySession.duration_seconds).label("total_seconds"),
            func.avg(TherapySession.accuracy).label("avg_accuracy"),
        )
        .where(and_(TherapySession.child_id == child_id, func.date(TherapySession.started_at) >= since))
        .group_by(func.date(TherapySession.started_at))
        .order_by(func.date(TherapySession.started_at))
    )

    return [
        {
            "date": row.date,
            "sessions": row.sessions,
            "total_minutes": (row.total_seconds or 0) // 60,
            "avg_accuracy": round(float(row.avg_accuracy), 3) if row.avg_accuracy else None,
        }
        for row in result
    ]
