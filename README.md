# KidNeuro Godot

ASD/ADHD Therapy Edu-Games Platform built with Godot 4.x, FastAPI, Next.js, and Expo.

Evidence-based therapeutic games designed to help children with Autism Spectrum Disorder (ASD) and Attention Deficit Hyperactivity Disorder (ADHD) develop essential life skills through engaging, adaptive gameplay.

## Features

- **6 Therapy Games** — Emotion Explorer, Focus Forest, Social Stories, Sensory Space, Task Tower, Word World
- **Adaptive Difficulty** — Auto-adjusts based on child's performance
- **Accessibility-First** — Large text, high contrast, reduce motion, colorblind modes, audio descriptions
- **Progress Tracking** — Detailed analytics for therapists and parents
- **Multi-Platform** — Godot exports to Web (HTML5), Android, iOS
- **REST API** — FastAPI with JWT auth, ready for integration
- **Therapist Dashboard** — Next.js web portal for monitoring and configuration
- **Mobile App** — Expo/React Native for parents with push notifications

## Quick Start

```bash
# Clone and setup
git clone https://github.com/tgunawandev/kidneuro-godot.git
cd kidneuro-godot
./bin/setup
```

Or manually:

```bash
# 1. Start infrastructure
./bin/ctl start

# 2. Setup API
./bin/api install
./bin/db migrate
./bin/db seed

# 3. Start development
./bin/api dev              # API at http://localhost:8000
./bin/expo dev             # Mobile app
./bin/godot editor         # Open Godot editor
```

## Project Structure

```
kidneuro-godot/
├── api/                   # FastAPI backend (Python 3.12)
│   ├── Dockerfile
│   ├── src/kidneuro/      # Models, routers, schemas, services
│   └── tests/
├── web/                   # Next.js 15 dashboard
│   ├── Dockerfile
│   └── app/
├── mobile/                # Expo React Native app
│   ├── app.json
│   └── app/
├── godot/                 # Godot 4.x game project
│   ├── project.godot
│   ├── scenes/games/      # Therapy game scenes
│   └── scripts/autoload/  # GameManager, ApiClient, Accessibility
├── nginx/                 # Serves Godot HTML5 exports
│   └── Dockerfile
├── bin/                   # CLI scripts
│   ├── ctl                # Server control
│   ├── db                 # Database operations
│   ├── api                # API management
│   ├── expo               # Mobile app management
│   ├── deploy             # Build & push Docker images
│   ├── godot              # Godot tools
│   ├── test               # Test runner
│   ├── backup             # Backup & restore
│   └── setup              # Initial project setup
├── docker-compose.yml     # Local development
├── docker-compose.prod.yml # Production (Dokploy-ready)
├── .env.example           # Environment template
└── .github/workflows/     # CI/CD
```

## CLI Commands

### Server Management
```bash
./bin/ctl start            # Start infrastructure
./bin/ctl status           # Health check all services
./bin/ctl logs [service]   # Follow logs
./bin/ctl stop             # Stop everything
```

### Database
```bash
./bin/db migrate           # Run migrations
./bin/db makemigration msg # Create migration
./bin/db seed              # Seed demo data
./bin/db shell             # Open psql
./bin/db backup            # Backup database
./bin/db restore <file>    # Restore from backup
./bin/db reset             # Drop, recreate, migrate, seed
```

### API
```bash
./bin/api dev              # Start with hot-reload
./bin/api test             # Run tests
./bin/api lint             # Lint code
./bin/api routes           # List all routes
./bin/api create-admin     # Create admin user
./bin/api openapi          # Generate OpenAPI spec
```

### Mobile (Expo)
```bash
./bin/expo dev             # Start dev server
./bin/expo dev android     # Start on Android
./bin/expo build android   # Build APK
./bin/expo build preview   # Build preview for testers
./bin/expo submit android  # Submit to Play Store
./bin/expo update "msg"    # OTA update
./bin/expo doctor          # Diagnostics
```

### Godot Games
```bash
./bin/godot editor         # Open Godot editor
./bin/godot export-html5   # Export for web
./bin/godot export-android # Export APK
./bin/godot list           # List scenes & scripts
```

### Deployment
```bash
./bin/deploy api           # Build & push API image
./bin/deploy web           # Build & push Web image
./bin/deploy games         # Build & push Games image
./bin/deploy all           # Build & push everything
./bin/deploy pull-restart  # Update running services
```

## Production Deployment

```bash
# Using docker-compose.prod.yml (Dokploy-compatible)
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Services:**

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `api-migrate` | kidneuro-api | — | Run migrations (exits) |
| `api` | kidneuro-api | 8000 | REST API (Gunicorn) |
| `worker` | kidneuro-api | — | Celery background tasks |
| `beat` | kidneuro-api | — | Scheduled tasks |
| `web` | kidneuro-web | 3000 | Dashboard (Next.js) |
| `games` | kidneuro-games | 8080 | Godot HTML5 (Nginx) |
| `postgres` | postgres:16 | 5432 | Database |
| `redis` | redis:7 | 6379 | Cache & task queue |

## API Documentation

Interactive docs at `http://localhost:8000/docs` (development only).

**Key endpoints:**

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/auth/register` | Register new user |
| `POST /api/v1/auth/login` | Login, returns JWT tokens |
| `GET /api/v1/children` | List children profiles |
| `GET /api/v1/games` | Game catalog |
| `POST /api/v1/sessions` | Start therapy session |
| `PATCH /api/v1/sessions/{id}` | Update session (score, metrics) |
| `GET /api/v1/analytics/children/{id}/progress` | Progress report |

## Game Categories

| Game | Category | Skills Targeted |
|------|----------|-----------------|
| Emotion Explorer | Emotional Regulation | Emotion recognition, empathy |
| Focus Forest | Attention & Focus | Sustained attention, impulse control |
| Social Stories | Social Skills | Turn-taking, greetings, sharing |
| Sensory Space | Sensory Processing | Self-regulation, calming |
| Task Tower | Executive Function | Planning, sequencing, working memory |
| Word World | Communication | Expressive/receptive language |

## Tech Stack

- **Games:** Godot 4.3 (GDScript)
- **API:** Python 3.12, FastAPI, SQLAlchemy 2.0, Celery, Redis
- **Web:** Next.js 15, React 19, Tailwind CSS, TanStack Query
- **Mobile:** Expo SDK 52, React Native, WebView (for Godot HTML5)
- **Database:** PostgreSQL 16, Redis 7
- **CI/CD:** GitHub Actions, GHCR, Docker
- **Deployment:** Docker Compose, Dokploy, Traefik

## Environment Variables

Copy `.env.example` to `.env` for development. See `.env.prod` for production variables.

Key variables: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET_KEY`, `EXPO_ACCESS_TOKEN`, `SENTRY_DSN`.

## License

MIT
