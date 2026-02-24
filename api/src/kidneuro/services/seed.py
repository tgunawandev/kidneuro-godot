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

        # Seed game catalog (18 games)
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
                sort_order=0,
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
                sort_order=1,
            ),
            Game(
                slug="memory-sequence",
                title="Memory Sequence",
                description="Watch and repeat color patterns to train working memory and sequencing",
                category=GameCategory.EXECUTIVE_FUNCTION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=12,
                godot_scene="res://scenes/games/memory_game.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["planning_score", "completion_rate"], "skills": ["planning", "sequencing", "working_memory"]},
                sort_order=2,
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
                sort_order=3,
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
                sort_order=4,
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
                sort_order=5,
            ),
            Game(
                slug="impulse-island",
                title="Impulse Island",
                description="Go/No-Go impulse control training. Tap friendly creatures, avoid scary ones!",
                category=GameCategory.ATTENTION_FOCUS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=12,
                godot_scene="res://scenes/games/impulse_island.tscn",
                target_diagnoses=["adhd"],
                therapy_goals={"metrics": ["false_alarm_rate", "reaction_time", "inhibition_score"], "skills": ["impulse_control", "response_inhibition", "selective_attention"]},
                sort_order=6,
            ),
            Game(
                slug="feeling-thermometer",
                title="Feeling Thermometer",
                description="Rate emotion intensity and choose the best coping strategy",
                category=GameCategory.EMOTIONAL_REGULATION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/feeling_thermometer.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["intensity_accuracy", "coping_quality"], "skills": ["emotion_regulation", "coping_strategies", "self_awareness"]},
                sort_order=7,
            ),
            Game(
                slug="routine-builder",
                title="Routine Builder",
                description="Arrange daily routine steps in the correct order",
                category=GameCategory.DAILY_LIVING,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=3, max_age=10,
                godot_scene="res://scenes/games/routine_builder.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["sequence_accuracy", "completion_time"], "skills": ["daily_routines", "planning", "independence"]},
                sort_order=8,
            ),
            Game(
                slug="pattern-puzzles",
                title="Pattern Puzzles",
                description="Complete patterns by finding what comes next",
                category=GameCategory.COGNITIVE,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=12,
                godot_scene="res://scenes/games/pattern_puzzles.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["pattern_accuracy", "response_time"], "skills": ["pattern_recognition", "cognitive_flexibility", "logical_thinking"]},
                sort_order=9,
            ),
            Game(
                slug="trace-draw",
                title="Trace & Draw",
                description="Connect the dots in order to reveal fun shapes",
                category=GameCategory.MOTOR_SKILLS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=3, max_age=10,
                godot_scene="res://scenes/games/trace_draw.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["precision_score", "completion_time"], "skills": ["fine_motor", "hand_eye_coordination", "visual_motor"]},
                sort_order=10,
            ),
            Game(
                slug="turn-taker",
                title="Turn Taker",
                description="Practice taking turns with a virtual friend in a dice game",
                category=GameCategory.SOCIAL_SKILLS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=4, max_age=10,
                godot_scene="res://scenes/games/turn_taker.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["wait_compliance", "social_responses"], "skills": ["turn_taking", "patience", "social_reciprocity"]},
                sort_order=11,
            ),
            Game(
                slug="mind-reader",
                title="Mind Reader",
                description="Figure out what characters think and feel in story scenarios (Theory of Mind)",
                category=GameCategory.SOCIAL_SKILLS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/mind_reader.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["accuracy", "response_time"], "skills": ["theory_of_mind", "perspective_taking", "false_belief_understanding"]},
                sort_order=12,
            ),
            Game(
                slug="flex-switch",
                title="Flex Switch",
                description="Sort cards by changing rules to train cognitive flexibility",
                category=GameCategory.COGNITIVE,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/flex_switch.tscn",
                target_diagnoses=["asd", "adhd"],
                therapy_goals={"metrics": ["accuracy", "perseveration_errors", "switch_cost"], "skills": ["cognitive_flexibility", "set_shifting", "rule_learning"]},
                sort_order=13,
            ),
            Game(
                slug="chat-builder",
                title="Chat Builder",
                description="Build conversations by choosing appropriate replies in chat scenarios",
                category=GameCategory.COMMUNICATION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/chat_builder.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["accuracy", "conversation_quality"], "skills": ["pragmatic_language", "conversational_turn_taking", "topic_maintenance"]},
                sort_order=14,
            ),
            Game(
                slug="time-timer",
                title="Time Timer",
                description="Estimate durations, compare time lengths, and build time awareness",
                category=GameCategory.EXECUTIVE_FUNCTION,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/time_timer.tscn",
                target_diagnoses=["adhd"],
                therapy_goals={"metrics": ["estimation_accuracy", "response_time"], "skills": ["time_perception", "time_management", "duration_estimation"]},
                sort_order=15,
            ),
            Game(
                slug="body-clues",
                title="Body Clues",
                description="Read body language and nonverbal cues to understand how people feel",
                category=GameCategory.SOCIAL_SKILLS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/body_clues.tscn",
                target_diagnoses=["asd"],
                therapy_goals={"metrics": ["accuracy", "response_time"], "skills": ["nonverbal_communication", "body_language_reading", "social_perception"]},
                sort_order=16,
            ),
            Game(
                slug="focus-filter",
                title="Focus Filter",
                description="Find target items among distractors to sharpen selective attention",
                category=GameCategory.ATTENTION_FOCUS,
                difficulty=GameDifficulty.ADAPTIVE,
                min_age=5, max_age=12,
                godot_scene="res://scenes/games/focus_filter.tscn",
                target_diagnoses=["adhd"],
                therapy_goals={"metrics": ["hit_rate", "false_alarm_rate", "d_prime"], "skills": ["selective_attention", "sustained_attention", "distractor_inhibition"]},
                sort_order=17,
            ),
        ]
        session.add_all(games)
        await session.commit()
