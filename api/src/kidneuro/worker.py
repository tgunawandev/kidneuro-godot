"""Celery worker for background tasks."""

from celery import Celery
from celery.schedules import crontab

from kidneuro.config import get_settings

settings = get_settings()

app = Celery(
    "kidneuro",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    result_expires=3600,
    beat_schedule={
        "daily-progress-report": {
            "task": "kidneuro.tasks.analytics.generate_daily_reports",
            "schedule": crontab(hour=6, minute=0),
        },
        "cleanup-abandoned-sessions": {
            "task": "kidneuro.tasks.sessions.cleanup_abandoned",
            "schedule": crontab(minute="*/30"),
        },
        "weekly-digest": {
            "task": "kidneuro.tasks.notifications.send_weekly_digest",
            "schedule": crontab(day_of_week=1, hour=8, minute=0),  # Monday 8am
        },
    },
)

app.autodiscover_tasks(["kidneuro.tasks"])
