"""Child model - the therapy recipients."""

import enum
import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from kidneuro.database import Base


class ChildDiagnosis(str, enum.Enum):
    ASD = "asd"
    ADHD = "adhd"
    ASD_ADHD = "asd_adhd"
    OTHER = "other"
    UNDIAGNOSED = "undiagnosed"


class Child(Base):
    __tablename__ = "children"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    parent_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    first_name: Mapped[str] = mapped_column(String(100))
    last_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    date_of_birth: Mapped[date] = mapped_column(Date)
    diagnosis: Mapped[ChildDiagnosis] = mapped_column(Enum(ChildDiagnosis), default=ChildDiagnosis.UNDIAGNOSED)
    diagnosis_details: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    grade_level: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Therapy preferences (stored as JSONB for flexibility)
    preferences: Mapped[dict | None] = mapped_column(JSONB, nullable=True, default=dict)
    # e.g.: {"sensory_sensitivity": "high", "preferred_colors": ["blue", "green"],
    #        "sound_enabled": true, "difficulty_level": "adaptive"}

    # Accessibility settings
    accessibility: Mapped[dict | None] = mapped_column(JSONB, nullable=True, default=dict)
    # e.g.: {"large_text": false, "high_contrast": false, "reduce_motion": true,
    #        "audio_descriptions": true}

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    parent: Mapped["User"] = relationship("User", back_populates="children")
    therapy_sessions: Mapped[list["TherapySession"]] = relationship("TherapySession", back_populates="child", cascade="all, delete-orphan")

    @property
    def age_years(self) -> int:
        today = date.today()
        return today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )

    def __repr__(self) -> str:
        return f"<Child {self.first_name} (age {self.age_years}, {self.diagnosis.value})>"
