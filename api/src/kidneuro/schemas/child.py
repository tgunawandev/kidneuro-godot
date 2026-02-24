"""Child schemas."""

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field

from kidneuro.models.child import ChildDiagnosis


class ChildCreate(BaseModel):
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str | None = None
    date_of_birth: date
    diagnosis: ChildDiagnosis = ChildDiagnosis.UNDIAGNOSED
    diagnosis_details: str | None = None
    grade_level: int | None = None
    preferences: dict | None = None
    accessibility: dict | None = None


class ChildUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    date_of_birth: date | None = None
    diagnosis: ChildDiagnosis | None = None
    diagnosis_details: str | None = None
    grade_level: int | None = None
    avatar_url: str | None = None
    preferences: dict | None = None
    accessibility: dict | None = None


class ChildResponse(BaseModel):
    id: uuid.UUID
    parent_id: uuid.UUID
    first_name: str
    last_name: str | None
    date_of_birth: date
    diagnosis: ChildDiagnosis
    diagnosis_details: str | None
    avatar_url: str | None
    grade_level: int | None
    preferences: dict | None
    accessibility: dict | None
    age_years: int
    created_at: datetime

    model_config = {"from_attributes": True}


class ChildListResponse(BaseModel):
    items: list[ChildResponse]
    total: int
