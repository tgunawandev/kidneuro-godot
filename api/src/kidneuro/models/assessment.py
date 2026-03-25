"""Assessment models — standardized instruments (CARS-2, Conners-3), custom goals, and scheduling."""

import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from kidneuro.database import Base


class InstrumentType(str, enum.Enum):
    STANDARDIZED = "standardized"
    CUSTOM_GOAL = "custom_goal"
    SCREENING = "screening"


class AssessmentType(str, enum.Enum):
    PRE = "pre"
    POST = "post"
    PERIODIC = "periodic"
    SCREENING = "screening"


class AssessmentStatus(str, enum.Enum):
    DRAFT = "draft"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    REVIEWED = "reviewed"


class AssessmentInstrument(Base):
    """A reusable assessment instrument (e.g., CARS-2, Conners-3, custom goal scale)."""

    __tablename__ = "assessment_instruments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    slug: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    version: Mapped[str] = mapped_column(String(20), default="1.0")
    instrument_type: Mapped[InstrumentType] = mapped_column(
        Enum(InstrumentType), default=InstrumentType.STANDARDIZED
    )

    # JSON schema for how to compute scores (cutoffs, subscales, normative tables)
    scoring_config: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # e.g. {"total_range": [15, 60], "cutoffs": {"minimal": 30, "mild_moderate": 36}}

    # Full item definitions: questions, scales, anchors
    item_definitions: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # e.g. {"items": [{"id": 1, "text": "Relating to people", "scale_min": 1, "scale_max": 4}]}

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    assessments: Mapped[list["Assessment"]] = relationship(
        "Assessment", back_populates="instrument", cascade="all, delete-orphan"
    )
    schedules: Mapped[list["AssessmentSchedule"]] = relationship(
        "AssessmentSchedule", back_populates="instrument", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<AssessmentInstrument {self.slug} v{self.version}>"


class Assessment(Base):
    """A single assessment administration for a child."""

    __tablename__ = "assessments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), index=True
    )
    instrument_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("assessment_instruments.id", ondelete="CASCADE"),
        index=True,
    )
    assessor_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )

    assessment_type: Mapped[AssessmentType] = mapped_column(
        Enum(AssessmentType), default=AssessmentType.PRE
    )
    status: Mapped[AssessmentStatus] = mapped_column(
        Enum(AssessmentStatus), default=AssessmentStatus.DRAFT
    )

    # Timing
    scheduled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Item-level responses: {"1": 3, "2": 2, ...}
    responses: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Computed scores: {"total": 28, "subscales": {"inattention": 65, ...}}
    scores: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Review tracking
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    instrument: Mapped["AssessmentInstrument"] = relationship(
        "AssessmentInstrument", back_populates="assessments"
    )
    child: Mapped["Child"] = relationship("Child")
    assessor: Mapped["User"] = relationship("User", foreign_keys=[assessor_id])

    def __repr__(self) -> str:
        return f"<Assessment {self.id} ({self.status.value})>"


class AssessmentSchedule(Base):
    """Recurring schedule for periodic reassessments."""

    __tablename__ = "assessment_schedules"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), index=True
    )
    instrument_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("assessment_instruments.id", ondelete="CASCADE"),
        index=True,
    )
    frequency_days: Mapped[int] = mapped_column(Integer, default=90)
    next_due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    last_completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    instrument: Mapped["AssessmentInstrument"] = relationship(
        "AssessmentInstrument", back_populates="schedules"
    )
    child: Mapped["Child"] = relationship("Child")

    def __repr__(self) -> str:
        return f"<AssessmentSchedule {self.id} every {self.frequency_days}d>"
