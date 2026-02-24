"""Therapy session endpoints."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user
from kidneuro.models.child import Child
from kidneuro.models.session import SessionEvent, SessionStatus, TherapySession
from kidneuro.models.user import User, UserRole
from kidneuro.schemas.session import (
    SessionCreate,
    SessionEventCreate,
    SessionEventResponse,
    SessionListResponse,
    SessionResponse,
    SessionUpdate,
)

router = APIRouter()


@router.post("", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def start_session(
    payload: SessionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TherapySession:
    # Verify child belongs to parent
    result = await db.execute(select(Child).where(Child.id == payload.child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
    if current_user.role == UserRole.PARENT and child.parent_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    session = TherapySession(**payload.model_dump())
    db.add(session)
    await db.flush()
    await db.refresh(session)
    return session


@router.get("", response_model=SessionListResponse)
async def list_sessions(
    child_id: uuid.UUID | None = None,
    status_filter: SessionStatus | None = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    query = select(TherapySession)
    count_query = select(func.count()).select_from(TherapySession)

    if current_user.role == UserRole.PARENT:
        child_ids_q = select(Child.id).where(Child.parent_id == current_user.id)
        query = query.where(TherapySession.child_id.in_(child_ids_q))
        count_query = count_query.where(TherapySession.child_id.in_(child_ids_q))

    if child_id:
        query = query.where(TherapySession.child_id == child_id)
        count_query = count_query.where(TherapySession.child_id == child_id)

    if status_filter:
        query = query.where(TherapySession.status == status_filter)
        count_query = count_query.where(TherapySession.status == status_filter)

    total = (await db.execute(count_query)).scalar() or 0
    result = await db.execute(
        query.offset((page - 1) * per_page).limit(per_page).order_by(TherapySession.started_at.desc())
    )
    return {"items": list(result.scalars().all()), "total": total, "page": page, "per_page": per_page}


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TherapySession:
    result = await db.execute(select(TherapySession).where(TherapySession.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")
    return session


@router.patch("/{session_id}", response_model=SessionResponse)
async def update_session(
    session_id: uuid.UUID,
    payload: SessionUpdate,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TherapySession:
    result = await db.execute(select(TherapySession).where(TherapySession.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "status" in update_data and update_data["status"] in (SessionStatus.COMPLETED, SessionStatus.ABANDONED):
        update_data["ended_at"] = datetime.now(timezone.utc)
        if session.started_at:
            update_data["duration_seconds"] = int((datetime.now(timezone.utc) - session.started_at).total_seconds())

    for field, value in update_data.items():
        setattr(session, field, value)

    await db.flush()
    await db.refresh(session)
    return session


@router.post("/{session_id}/events", response_model=SessionEventResponse, status_code=status.HTTP_201_CREATED)
async def add_event(
    session_id: uuid.UUID,
    payload: SessionEventCreate,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SessionEvent:
    result = await db.execute(select(TherapySession).where(TherapySession.id == session_id))
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")

    event = SessionEvent(session_id=session_id, **payload.model_dump())
    db.add(event)
    await db.flush()
    await db.refresh(event)
    return event


@router.get("/{session_id}/events", response_model=list[SessionEventResponse])
async def list_events(
    session_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[SessionEvent]:
    result = await db.execute(
        select(SessionEvent).where(SessionEvent.session_id == session_id).order_by(SessionEvent.timestamp)
    )
    return list(result.scalars().all())
