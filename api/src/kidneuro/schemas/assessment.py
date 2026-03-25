"""Assessment schemas — request/response validation for instruments, assessments, and schedules."""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from kidneuro.models.assessment import AssessmentStatus, AssessmentType, InstrumentType


# ── Instrument ──────────────────────────────────────────────────────────────


class InstrumentResponse(BaseModel):
    id: uuid.UUID
    slug: str
    name: str
    description: str | None
    version: str
    instrument_type: InstrumentType
    scoring_config: dict | None
    item_definitions: dict | None
    is_active: bool

    model_config = {"from_attributes": True}


# ── Assessment ──────────────────────────────────────────────────────────────


class AssessmentCreate(BaseModel):
    child_id: uuid.UUID
    instrument_id: uuid.UUID
    assessment_type: AssessmentType = AssessmentType.PRE
    scheduled_at: datetime | None = None
    notes: str | None = None


class AssessmentUpdate(BaseModel):
    status: AssessmentStatus | None = None
    responses: dict[str, Any] | None = None
    scores: dict[str, Any] | None = None
    notes: str | None = None
    reviewed_by: uuid.UUID | None = None


class AssessmentResponse(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    instrument_id: uuid.UUID
    assessor_id: uuid.UUID
    assessment_type: AssessmentType
    status: AssessmentStatus
    scheduled_at: datetime | None
    started_at: datetime | None
    completed_at: datetime | None
    responses: dict | None
    scores: dict | None
    notes: str | None
    reviewed_by: uuid.UUID | None
    reviewed_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class AssessmentListResponse(BaseModel):
    items: list[AssessmentResponse]
    total: int
    page: int
    per_page: int


# ── Pre/Post Comparison ────────────────────────────────────────────────────


class ComparisonResponse(BaseModel):
    child_id: uuid.UUID
    instrument_slug: str
    pre_assessment: AssessmentResponse | None
    post_assessment: AssessmentResponse | None
    score_change: dict[str, Any] | None = None
    effect_size: float | None = Field(None, description="Cohen's d")
    reliable_change_index: float | None = Field(None, description="RCI z-score")
    clinically_significant: bool | None = None


# ── Schedule ────────────────────────────────────────────────────────────────


class ScheduleCreate(BaseModel):
    child_id: uuid.UUID
    instrument_id: uuid.UUID
    frequency_days: int = Field(90, ge=7, le=365)
    next_due_at: datetime


class ScheduleResponse(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    instrument_id: uuid.UUID
    frequency_days: int
    next_due_at: datetime
    last_completed_at: datetime | None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
