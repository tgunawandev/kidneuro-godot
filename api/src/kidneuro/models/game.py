"""Game model - therapy edu-games catalog."""

import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from kidneuro.database import Base


class GameCategory(str, enum.Enum):
    SOCIAL_SKILLS = "social_skills"
    EMOTIONAL_REGULATION = "emotional_regulation"
    ATTENTION_FOCUS = "attention_focus"
    EXECUTIVE_FUNCTION = "executive_function"
    SENSORY_PROCESSING = "sensory_processing"
    COMMUNICATION = "communication"
    MOTOR_SKILLS = "motor_skills"
    DAILY_LIVING = "daily_living"
    COGNITIVE = "cognitive"


class GameDifficulty(str, enum.Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    ADAPTIVE = "adaptive"


class Game(Base):
    __tablename__ = "games"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    slug: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)
    category: Mapped[GameCategory] = mapped_column(Enum(GameCategory), index=True)
    difficulty: Mapped[GameDifficulty] = mapped_column(Enum(GameDifficulty), default=GameDifficulty.ADAPTIVE)

    # Target demographics
    min_age: Mapped[int] = mapped_column(Integer, default=3)
    max_age: Mapped[int] = mapped_column(Integer, default=12)
    target_diagnoses: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)

    # Game metadata
    version: Mapped[str] = mapped_column(String(20), default="1.0.0")
    godot_scene: Mapped[str] = mapped_column(String(255))  # Path to Godot scene
    thumbnail_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    html5_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # Therapy goals tracked by this game
    therapy_goals: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # e.g.: {"metrics": ["response_time", "accuracy", "emotional_recognition"],
    #        "skills": ["turn_taking", "eye_contact_simulation"]}

    # Configuration schema for the game
    config_schema: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def __repr__(self) -> str:
        return f"<Game {self.slug} ({self.category.value})>"
