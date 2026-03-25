"""Consent schemas — request/response validation for consent management."""

import uuid
from datetime import datetime

from pydantic import BaseModel

from kidneuro.models.consent import ConsentStatus, ConsentType


class ConsentGrant(BaseModel):
    child_id: uuid.UUID
    consent_type: ConsentType
    document_version: str = "1.0"
    document_hash: str | None = None


class ConsentWithdraw(BaseModel):
    reason: str | None = None


class ConsentResponse(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    granted_by: uuid.UUID | None
    consent_type: ConsentType
    status: ConsentStatus
    granted_at: datetime
    withdrawn_at: datetime | None
    document_version: str
    document_hash: str | None

    model_config = {"from_attributes": True}


class ConsentListResponse(BaseModel):
    items: list[ConsentResponse]
    total: int


class ConsentCheckResponse(BaseModel):
    child_id: uuid.UUID
    consent_type: ConsentType
    has_active_consent: bool
    consent: ConsentResponse | None = None
