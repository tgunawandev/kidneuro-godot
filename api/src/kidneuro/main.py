"""FastAPI application entry point."""

from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

import sentry_sdk
import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

from kidneuro.config import get_settings
from kidneuro.routers import auth, children, games, health, sessions, users, analytics

settings = get_settings()
logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # Startup
    logger.info("Starting KidNeuro API", env=settings.app_env, version="0.1.0")

    if settings.sentry_dsn:
        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.sentry_environment,
            traces_sample_rate=settings.sentry_traces_sample_rate,
        )

    yield

    # Shutdown
    logger.info("Shutting down KidNeuro API")


app = FastAPI(
    title="KidNeuro API",
    description="ASD/ADHD Therapy Edu-Games Platform - REST API",
    version="0.1.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    lifespan=lifespan,
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if settings.is_production:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=[h.strip() for h in settings.allowed_hosts.split(",")],
    )

# Routers
app.include_router(health.router)
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(children.router, prefix="/api/v1/children", tags=["Children"])
app.include_router(games.router, prefix="/api/v1/games", tags=["Games"])
app.include_router(sessions.router, prefix="/api/v1/sessions", tags=["Therapy Sessions"])
app.include_router(analytics.router, prefix="/api/v1/analytics", tags=["Analytics"])
