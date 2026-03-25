"""Consent endpoints — grant, withdraw, and check parental consent records."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user
from kidneuro.models.child import Child
from kidneuro.models.consent import Consent, ConsentStatus, ConsentType
from kidneuro.models.user import User, UserRole
from kidneuro.schemas.consent import (
    ConsentCheckResponse,
    ConsentGrant,
    ConsentListResponse,
    ConsentResponse,
    ConsentWithdraw,
)

router = APIRouter()


@router.post("", response_model=ConsentResponse, status_code=status.HTTP_201_CREATED)
async def grant_consent(
    payload: ConsentGrant,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Consent:
    """Grant consent for a specific data processing purpose."""
    # Verify child exists and belongs to user (parents only see their own children)
    result = await db.execute(select(Child).where(Child.id == payload.child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
    if current_user.role == UserRole.PARENT and child.parent_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    # Check for existing active consent of this type — withdraw it first
    existing = await db.execute(
        select(Consent).where(
            Consent.child_id == payload.child_id,
            Consent.consent_type == payload.consent_type,
            Consent.status == ConsentStatus.ACTIVE,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Active consent for '{payload.consent_type.value}' already exists. "
            "Withdraw it first to re-grant.",
        )

    consent = Consent(
        child_id=payload.child_id,
        granted_by=current_user.id,
        consent_type=payload.consent_type,
        document_version=payload.document_version,
        document_hash=payload.document_hash,
    )
    db.add(consent)
    await db.flush()
    await db.refresh(consent)
    return consent


@router.post("/{consent_id}/withdraw", response_model=ConsentResponse)
async def withdraw_consent(
    consent_id: uuid.UUID,
    payload: ConsentWithdraw,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Consent:
    """Withdraw a previously granted consent."""
    result = await db.execute(select(Consent).where(Consent.id == consent_id))
    consent = result.scalar_one_or_none()
    if not consent:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Consent not found")

    # Only the granting user (or admin) may withdraw
    if current_user.role == UserRole.PARENT and consent.granted_by != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    if consent.status == ConsentStatus.WITHDRAWN:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Consent already withdrawn"
        )

    consent.status = ConsentStatus.WITHDRAWN
    consent.withdrawn_at = datetime.now(timezone.utc)

    await db.flush()
    await db.refresh(consent)
    return consent


@router.get("/children/{child_id}", response_model=ConsentListResponse)
async def list_child_consents(
    child_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """List all consent records (active and withdrawn) for a child."""
    query = select(Consent).where(Consent.child_id == child_id).order_by(Consent.granted_at.desc())
    count_query = select(func.count()).select_from(Consent).where(Consent.child_id == child_id)

    total = (await db.execute(count_query)).scalar() or 0
    result = await db.execute(query)
    return {"items": list(result.scalars().all()), "total": total}


@router.get("/check/{child_id}/{consent_type}", response_model=ConsentCheckResponse)
async def check_consent(
    child_id: uuid.UUID,
    consent_type: ConsentType,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Check whether a child has active consent for a specific purpose."""
    result = await db.execute(
        select(Consent).where(
            Consent.child_id == child_id,
            Consent.consent_type == consent_type,
            Consent.status == ConsentStatus.ACTIVE,
        )
    )
    active_consent = result.scalar_one_or_none()

    return {
        "child_id": child_id,
        "consent_type": consent_type,
        "has_active_consent": active_consent is not None,
        "consent": active_consent,
    }
