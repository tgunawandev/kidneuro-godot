"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    app_name: str = "kidneuro"
    app_env: Literal["development", "staging", "production"] = "development"
    app_debug: bool = False
    app_secret_key: str = "changeme"
    app_url: str = "http://localhost:3000"
    api_url: str = "http://localhost:8000"
    allowed_hosts: str = "localhost,127.0.0.1"
    cors_origins: str = "http://localhost:3000,http://localhost:8081"

    # Database
    database_url: str = "postgresql+asyncpg://kidneuro:kidneuro_dev_password@localhost:5432/kidneuro_dev"
    postgres_max_connections: int = 100

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "changeme"
    jwt_refresh_secret: str = "changeme"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7
    jwt_algorithm: str = "HS256"

    # Encryption
    encryption_key: str = "changeme"
    api_key_salt: str = "changeme"

    # SMTP
    smtp_host: str = "localhost"
    smtp_port: int = 1025
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_tls: bool = False
    email_from: str = "KidNeuro <noreply@kidneuro.app>"
    contact_email: str = "support@kidneuro.app"

    # S3
    s3_endpoint: str = ""
    s3_access_key: str = ""
    s3_secret_key: str = ""
    s3_bucket: str = "kidneuro-assets"
    s3_region: str = "ap-southeast-1"

    # Expo Push
    expo_access_token: str = ""
    expo_project_id: str = ""

    # Sentry
    sentry_dsn: str = ""
    sentry_environment: str = "development"
    sentry_traces_sample_rate: float = 0.1

    # Logging
    log_level: str = "info"
    log_format: Literal["json", "text"] = "text"

    # Game config
    game_session_max_duration_minutes: int = 45
    game_break_reminder_minutes: int = 15
    game_max_daily_sessions: int = 3
    game_difficulty_auto_adjust: bool = True

    # Data protection
    audit_log_enabled: bool = True
    phi_encryption_enabled: bool = False
    consent_required: bool = True

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()
