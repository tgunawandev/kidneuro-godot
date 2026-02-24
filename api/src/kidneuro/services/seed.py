"""Database seeding for development and initial setup."""

import uuid
from datetime import date

from passlib.context import CryptContext

from kidneuro.database import async_session
from kidneuro.models.child import Child, ChildDiagnosis
from kidneuro.models.game import Game, GameCategory, GameDifficulty
from kidneuro.models.user import User, UserRole

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def create_admin_user(email: str, password: str, name: str) -> None:
    async with async_session() as session:
        user = User(
            email=email,
            hashed_password=pwd_context.hash(password),
            full_name=name,
            role=UserRole.ADMIN,
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()


async def seed_database() -> None:
    async with async_session() as session:
        # Create demo users
        parent = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000001"),
            email="parent@demo.kidneuro.app",
            hashed_password=pwd_context.hash("demo1234"),
            full_name="Demo Parent",
            role=UserRole.PARENT,
            is_active=True,
            is_verified=True,
        )
        therapist = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000002"),
            email="therapist@demo.kidneuro.app",
            hashed_password=pwd_context.hash("demo1234"),
            full_name="Dr. Demo Therapist",
            role=UserRole.THERAPIST,
            is_active=True,
            is_verified=True,
        )

        session.add_all([parent, therapist])
        await session.flush()

        # Create demo child
        child = Child(
            parent_id=parent.id,
            first_name="Alex",
            last_name="Demo",
            date_of_birth=date(2019, 6, 15),
            diagnosis=ChildDiagnosis.ASD,
            preferences={"sensory_sensitivity": "moderate", "sound_enabled": True},
            accessibility={"reduce_motion": False, "large_text": False},
        )
        session.add(child)

        # Seed game catalog
        games = [
            Game(
                slug="emotion-explorer",
                title="Emotion Explorer",
                description="Identify and match emotions through interactive scenarios",
                category=GameCategory.EMOTIONAL_REGULATION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=10,
                godot_scene="res://scenes/games/emotion_explorer.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["accuracy", "response_time"], "skills": ["emotion_recognition", "empathy"]},
            ),
            Game(
                slug="focus-forest",
                title="Focus Forest",
                description="Build a magical forest by maintaining focus on tasks",
                category=GameCategory.ATTENTION_FOCUS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/focus_forest.tscn",
                target_diagnoses=["adhd"],
                therapy_goals={"metrics": ["sustained_attention", "response_time"], "skills": ["focus", "impulse_control"]},
            ),
            Game(
                slug="social-stories",
                title="Social Stories",
                description="Navigate social scenarios and practice appropriate responses",
                category=GameCategory.SOCIAL_SKILLS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=10,
                godot_scene="res://scenes/games/social_stories.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["accuracy", "choice_quality"], "skills": ["turn_taking", "greetings", "sharing"]},
            ),
            Game(
                slug="sensory-space",
                title="Sensory Space",
                description="Calming sensory activities for regulation and decompression",
                category=GameCategory.SENSORY_PROCESSING,
                difficulty=GameDifficulty.EASY,
                min_age=3, max_age=8,
                godot_scene="res://scenes/games/sensory_space.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["engagement_time", "calm_score"], "skills": ["self_regulation", "sensory_awareness"]},
            ),
            Game(
                slug="task-tower",
                title="Task Tower",
                description="Practice executive function by planning and executing multi-step tasks",
                category=GameCategory.EXECUTIVE_FUNCTION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=6, max_age=12,
                godot_scene="res://scenes/games/task_tower.tscn",
                target_diagnoses=["adhd", "asd_adhd"],
                therapy_goals={"metrics": ["planning_score", "completion_rate"], "skills": ["planning", "sequencing", "working_memory"]},
            ),
            Game(
                slug="word-world",
                title="Word World",
                description="Build vocabulary and practice communication through interactive word games",
                category=GameCategory.COMMUNICATION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=10,
                godot_scene="res://scenes/games/word_world.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["vocabulary_score", "response_time"], "skills": ["expressive_language", "receptive_language"]},
            ),
        ]
        session.add_all(games)
        await session.commit()
