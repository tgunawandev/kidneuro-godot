# KidNeuro Godot - AI Development Guide

ASD/ADHD Therapy Edu-Games Platform built with Godot 4.x, FastAPI, Next.js, and Expo.

## Architecture

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Expo Mobile │   │  Next.js Web │   │ Godot HTML5  │
│  (parents)   │   │  (dashboard) │   │  (games)     │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                   │
       └──────────┬───────┴───────────────────┘
                  │
           ┌──────┴──────┐
           │ FastAPI API  │
           └──────┬──────┘
           ┌──────┴──────┐
           │ PostgreSQL   │──── Redis
           └─────────────┘
```

## Directory Structure

| Path | Description |
|------|-------------|
| `api/` | FastAPI backend (Python 3.12, SQLAlchemy 2.0, Celery) |
| `api/src/kidneuro/` | Main package (models, routers, schemas, services) |
| `web/` | Next.js 15 dashboard (therapist/parent portal) |
| `mobile/` | Expo/React Native mobile app |
| `godot/` | Godot 4.x game project |
| `godot/scripts/autoload/` | Singletons: GameManager, ApiClient, AccessibilityManager |
| `godot/scenes/games/` | Individual therapy game scenes |
| `nginx/` | Nginx serving Godot HTML5 exports |
| `bin/` | CLI scripts (ctl, db, api, expo, deploy, godot, test, backup, setup) |

## CLI Scripts

| Script | Purpose | Key Commands |
|--------|---------|-------------|
| `bin/ctl` | Server control | `start`, `stop`, `restart`, `status`, `logs` |
| `bin/db` | Database ops | `migrate`, `seed`, `reset`, `shell`, `backup`, `restore` |
| `bin/api` | API management | `dev`, `test`, `lint`, `routes`, `create-admin`, `openapi` |
| `bin/expo` | Mobile app | `dev`, `build`, `submit`, `update`, `doctor` |
| `bin/deploy` | Deployment | `api`, `web`, `games`, `all`, `pull-restart` |
| `bin/godot` | Godot tools | `editor`, `export-html5`, `export-android`, `list` |
| `bin/test` | Test runner | `api`, `web`, `mobile`, `lint`, `all` |
| `bin/backup` | Backup ops | `db`, `list`, `prune` |
| `bin/setup` | Initial setup | Runs full project setup interactively |

## Quick Development

```bash
# First time setup
./bin/setup

# Daily workflow
./bin/ctl start             # Start PostgreSQL + Redis + Mailpit
./bin/api dev               # Start API with hot-reload (localhost:8000)
./bin/expo dev              # Start Expo dev server

# Database
./bin/db migrate            # Run migrations
./bin/db makemigration msg  # Create new migration
./bin/db seed               # Seed demo data
./bin/db shell              # Open psql

# API
./bin/api routes            # List all routes
./bin/api test              # Run pytest
./bin/api openapi           # Generate OpenAPI spec

# Mobile
./bin/expo dev android      # Start on Android
./bin/expo build preview    # Build preview APK
./bin/expo update "msg"     # OTA update

# Godot
./bin/godot editor          # Open Godot editor
./bin/godot export-html5    # Export for web
```

## Production Deployment

```bash
# Build and push all Docker images
./bin/deploy login
./bin/deploy all

# On server: pull and restart
./bin/deploy pull-restart

# Or use docker compose directly
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Docker Architecture (Production):**
- `api-migrate` → Runs DB migrations then exits
- `api` → FastAPI (Gunicorn + Uvicorn workers)
- `worker` → Celery worker (analytics, reports, notifications)
- `beat` → Celery beat (scheduled tasks)
- `web` → Next.js dashboard
- `games` → Nginx serving Godot HTML5 exports
- `postgres` → PostgreSQL 16
- `redis` → Redis 7 (cache, sessions, task queue)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/register` | Register user |
| POST | `/api/v1/auth/login` | Login (returns JWT) |
| POST | `/api/v1/auth/refresh` | Refresh token |
| GET | `/api/v1/auth/me` | Current user profile |
| GET/PATCH | `/api/v1/users/{id}` | User CRUD |
| GET/POST | `/api/v1/children` | Child profiles |
| GET/PATCH/DELETE | `/api/v1/children/{id}` | Child CRUD |
| GET/POST | `/api/v1/games` | Game catalog |
| GET/POST | `/api/v1/sessions` | Therapy sessions |
| PATCH | `/api/v1/sessions/{id}` | Update session (score, status) |
| POST | `/api/v1/sessions/{id}/events` | Record session event |
| GET | `/api/v1/analytics/children/{id}/progress` | Child progress summary |
| GET | `/api/v1/analytics/children/{id}/daily` | Daily activity chart |
| GET | `/health` | Health check |

**Interactive docs:** `http://localhost:8000/docs` (dev only)

## Data Models

- **User** → roles: parent, therapist, admin
- **Child** → linked to parent, has diagnosis (ASD/ADHD), preferences, accessibility settings
- **Game** → catalog of therapy games with categories and therapy goals
- **TherapySession** → tracks gameplay: duration, score, accuracy, difficulty, metrics
- **SessionEvent** → fine-grained events within a session for analytics

## Game Categories (Godot)

| Category | Therapy Focus |
|----------|--------------|
| `emotion_explorer` | Emotional regulation, empathy |
| `focus_forest` | Sustained attention, impulse control |
| `social_stories` | Social skills, turn-taking |
| `sensory_space` | Sensory processing, self-regulation |
| `task_tower` | Executive function, planning |
| `word_world` | Communication, language |

## Godot Autoloads

| Singleton | Purpose |
|-----------|---------|
| `GameManager` | Session tracking, scoring, difficulty adaptation |
| `ApiClient` | HTTP client for REST API communication |
| `AudioManager` | Sound management with accessibility controls |
| `AccessibilityManager` | Large text, high contrast, reduce motion, colorblind modes |

## Environment

- API: `http://localhost:8000` (FastAPI + Swagger)
- Web: `http://localhost:3000` (Next.js)
- Mail: `http://localhost:8025` (Mailpit)
- DB: `localhost:5432` (PostgreSQL)
- Redis: `localhost:6379`

## Key Design Decisions

1. **Godot for games** → Better performance than web-only, exports to HTML5/Android/iOS
2. **FastAPI async** → High-performance API with SQLAlchemy 2.0 async
3. **JWT auth** → Stateless auth works across web, mobile, and game clients
4. **JSONB for metrics** → Flexible game-specific data without schema changes
5. **Celery workers** → Background analytics, report generation, notifications
6. **Adaptive difficulty** → Auto-adjusts based on child's accuracy (GameManager)
7. **Accessibility-first** → Built-in support for sensory sensitivities (AccessibilityManager)

## File Patterns

- API Models: `api/src/kidneuro/models/*.py`
- API Routes: `api/src/kidneuro/routers/*.py`
- API Schemas: `api/src/kidneuro/schemas/*.py`
- Godot Scenes: `godot/scenes/**/*.tscn`
- Godot Scripts: `godot/scripts/**/*.gd`
- Web Pages: `web/app/**/page.tsx`
- Mobile Screens: `mobile/app/**/*.tsx`
