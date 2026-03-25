"""Consent model — tracks parental/guardian consent for data processing (UU PDP compliance)."""

import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from kidneuro.database import Base


class ConsentType(str, enum.Enum):
    DATA_PROCESSING = "data_processing"
    VIDEO_RECORDING = "video_recording"
    RESEARCH_USE = "research_use"
    DATA_SHARING_CLINIC = "data_sharing_clinic"
    MARKETING = "marketing"


class ConsentStatus(str, enum.Enum):
    ACTIVE = "active"
    WITHDRAWN = "withdrawn"


class Consent(Base):
    """Immutable consent record — new rows for grant/withdrawal, never updated in place."""

    __tablename__ = "consents"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), index=True
    )
    granted_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    consent_type: Mapped[ConsentType] = mapped_column(Enum(ConsentType), index=True)
    status: Mapped[ConsentStatus] = mapped_column(
        Enum(ConsentStatus), default=ConsentStatus.ACTIVE
    )

    granted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    withdrawn_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Version and hash of the consent document presented to the guardian
    document_version: Mapped[str] = mapped_column(String(20), default="1.0")
    document_hash: Mapped[str | None] = mapped_column(String(128), nullable=True)

    def __repr__(self) -> str:
        return f"<Consent {self.consent_type.value} [{self.status.value}] child={self.child_id}>"
