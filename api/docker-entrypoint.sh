#!/bin/bash
set -euo pipefail

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
until pg_isready -h "${POSTGRES_HOST:-postgres}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-kidneuro}" -q; do
    sleep 1
done
echo "PostgreSQL ready."

case "${1:-serve}" in
    serve)
        echo "Starting API server..."
        exec gunicorn kidneuro.main:app \
            --bind 0.0.0.0:8000 \
            --worker-class uvicorn.workers.UvicornWorker \
            --workers "${API_WORKERS:-4}" \
            --max-requests "${API_MAX_REQUESTS:-1000}" \
            --max-requests-jitter "${API_MAX_REQUESTS_JITTER:-50}" \
            --timeout "${API_TIMEOUT:-120}" \
            --graceful-timeout 30 \
            --access-logfile - \
            --error-logfile -
        ;;
    migrate)
        echo "Running database migrations..."
        alembic upgrade head
        echo "Migrations complete."
        ;;
    worker)
        echo "Starting Celery worker..."
        exec celery -A kidneuro.worker.app worker \
            --loglevel="${LOG_LEVEL:-info}" \
            --concurrency="${CELERY_CONCURRENCY:-4}" \
            --max-tasks-per-child="${CELERY_MAX_TASKS_PER_CHILD:-100}" \
            -Q default,analytics,notifications,reports
        ;;
    beat)
        echo "Starting Celery beat scheduler..."
        exec celery -A kidneuro.worker.app beat \
            --loglevel="${LOG_LEVEL:-info}" \
            --schedule=/tmp/celerybeat-schedule
        ;;
    shell)
        echo "Starting interactive shell..."
        exec python -c "
from kidneuro.main import app
from kidneuro.database import async_session
import asyncio
print('KidNeuro Shell - app and async_session available')
import IPython; IPython.embed()
"
        ;;
    test)
        echo "Running tests..."
        exec pytest "${@:2}"
        ;;
    *)
        exec "$@"
        ;;
esac
