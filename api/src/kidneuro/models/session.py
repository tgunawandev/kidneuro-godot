"""Therapy session model - tracks gameplay and therapy progress."""

import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Float, String, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from kidneuro.database import Base


class SessionStatus(str, enum.Enum):
    STARTED = "started"
    IN_PROGRESS = "in_progress"
    PAUSED = "paused"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class TherapySession(Base):
    __tablename__ = "therapy_sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("children.id", ondelete="CASCADE"), index=True)
    game_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("games.id", ondelete="SET NULL"), index=True)
    status: Mapped[SessionStatus] = mapped_column(Enum(SessionStatus), default=SessionStatus.STARTED)

    # Timing
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    pause_count: Mapped[int] = mapped_column(Integer, default=0)

    # Performance metrics
    score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    accuracy: Mapped[float | None] = mapped_column(Float, nullable=True)  # 0.0 - 1.0
    avg_response_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    difficulty_level: Mapped[int] = mapped_column(Integer, default=1)  # 1-10

    # Detailed metrics (JSONB for game-specific data)
    metrics: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # e.g.: {"correct_answers": 8, "total_questions": 10,
    #        "emotional_responses": ["happy", "confused", "happy"],
    #        "attention_lapses": 2, "hints_used": 1}

    # Game configuration used for this session
    game_config: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Therapist/parent notes
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    child: Mapped["Child"] = relationship("Child", back_populates="therapy_sessions")
    events: Mapped[list["SessionEvent"]] = relationship("SessionEvent", back_populates="session", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<TherapySession {self.id} ({self.status.value})>"


class SessionEvent(Base):
    """Fine-grained events within a therapy session for detailed analytics."""
    __tablename__ = "session_events"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("therapy_sessions.id", ondelete="CASCADE"), index=True)
    event_type: Mapped[str] = mapped_column(String(50), index=True)
    # Types: "game_start", "game_pause", "game_resume", "answer_correct",
    #        "answer_incorrect", "hint_requested", "difficulty_adjusted",
    #        "break_taken", "emotional_check", "game_complete"
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    data: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    session: Mapped["TherapySession"] = relationship("TherapySession", back_populates="events")

    def __repr__(self) -> str:
        return f"<SessionEvent {self.event_type} at {self.timestamp}>"
