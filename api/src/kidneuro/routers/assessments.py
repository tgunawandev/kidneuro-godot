"""Assessment endpoints — instruments, administrations, schedules, and pre/post comparison."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.database import get_db
from kidneuro.middleware.auth import get_current_user, require_role
from kidneuro.models.assessment import (
    Assessment,
    AssessmentInstrument,
    AssessmentSchedule,
    AssessmentStatus,
    AssessmentType,
)
from kidneuro.models.child import Child
from kidneuro.models.user import User, UserRole
from kidneuro.schemas.assessment import (
    AssessmentCreate,
    AssessmentListResponse,
    AssessmentResponse,
    AssessmentUpdate,
    ComparisonResponse,
    InstrumentResponse,
    ScheduleCreate,
    ScheduleResponse,
)
from kidneuro.services.assessment_scoring import (
    compute_comparison,
    score_cars2,
    score_conners3,
    score_custom_goal,
)

router = APIRouter()

# ── Instruments ─────────────────────────────────────────────────────────────


@router.get("/instruments", response_model=list[InstrumentResponse])
async def list_instruments(
    active_only: bool = Query(True),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[AssessmentInstrument]:
    """List available assessment instruments."""
    query = select(AssessmentInstrument)
    if active_only:
        query = query.where(AssessmentInstrument.is_active.is_(True))
    query = query.order_by(AssessmentInstrument.name)
    result = await db.execute(query)
    return list(result.scalars().all())


# ── Child-scoped queries ────────────────────────────────────────────────────
# NOTE: These must be registered BEFORE /{assessment_id} to avoid path conflicts.


@router.get(
    "/children/{child_id}/list",
    response_model=AssessmentListResponse,
)
async def list_child_assessments(
    child_id: uuid.UUID,
    instrument_slug: str | None = Query(None),
    assessment_type: AssessmentType | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Paginated list of assessments for a child, with optional filters."""
    query = select(Assessment).where(Assessment.child_id == child_id)
    count_query = select(func.count()).select_from(Assessment).where(Assessment.child_id == child_id)

    if instrument_slug:
        instr_q = select(AssessmentInstrument.id).where(
            AssessmentInstrument.slug == instrument_slug
        )
        query = query.where(Assessment.instrument_id.in_(instr_q))
        count_query = count_query.where(Assessment.instrument_id.in_(instr_q))

    if assessment_type:
        query = query.where(Assessment.assessment_type == assessment_type)
        count_query = count_query.where(Assessment.assessment_type == assessment_type)

    total = (await db.execute(count_query)).scalar() or 0
    result = await db.execute(
        query.offset((page - 1) * per_page)
        .limit(per_page)
        .order_by(Assessment.created_at.desc())
    )
    return {
        "items": list(result.scalars().all()),
        "total": total,
        "page": page,
        "per_page": per_page,
    }


@router.get("/children/{child_id}/compare", response_model=ComparisonResponse)
async def compare_assessments(
    child_id: uuid.UUID,
    instrument_slug: str = Query(..., description="Instrument slug to compare"),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Compare pre and post assessments for outcome evidence (effect size, RCI)."""
    # Resolve instrument
    result = await db.execute(
        select(AssessmentInstrument).where(AssessmentInstrument.slug == instrument_slug)
    )
    instrument = result.scalar_one_or_none()
    if not instrument:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Instrument not found")

    # Fetch most recent completed pre and post
    pre = await _latest_completed(db, child_id, instrument.id, AssessmentType.PRE)
    post = await _latest_completed(db, child_id, instrument.id, AssessmentType.POST)

    comparison: dict | None = None
    effect_size: float | None = None
    rci: float | None = None
    clinically_significant: bool | None = None

    if pre and post and pre.scores and post.scores:
        # Extract normative SD from instrument config if available
        norm_sd = None
        if instrument.scoring_config:
            norm_sd = instrument.scoring_config.get("normative_sd")

        stats = compute_comparison(pre.scores, post.scores, normative_sd=norm_sd)
        comparison = stats.get("score_change")
        effect_size = stats.get("effect_size")
        rci = stats.get("reliable_change_index")
        clinically_significant = stats.get("clinically_significant")

    return {
        "child_id": child_id,
        "instrument_slug": instrument_slug,
        "pre_assessment": pre,
        "post_assessment": post,
        "score_change": comparison,
        "effect_size": effect_size,
        "reliable_change_index": rci,
        "clinically_significant": clinically_significant,
    }


@router.get("/children/{child_id}/due", response_model=list[ScheduleResponse])
async def list_due_assessments(
    child_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[AssessmentSchedule]:
    """List assessment schedules that are currently due for a child."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(AssessmentSchedule)
        .where(
            AssessmentSchedule.child_id == child_id,
            AssessmentSchedule.is_active.is_(True),
            AssessmentSchedule.next_due_at <= now,
        )
        .order_by(AssessmentSchedule.next_due_at)
    )
    return list(result.scalars().all())


# ── Schedules ───────────────────────────────────────────────────────────────


@router.post(
    "/schedules",
    response_model=ScheduleResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_schedule(
    payload: ScheduleCreate,
    _user: User = Depends(require_role(UserRole.THERAPIST, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db),
) -> AssessmentSchedule:
    """Create a recurring assessment schedule for a child (therapist/admin only)."""
    schedule = AssessmentSchedule(**payload.model_dump())
    db.add(schedule)
    await db.flush()
    await db.refresh(schedule)
    return schedule


# ── CRUD ────────────────────────────────────────────────────────────────────


@router.post("", response_model=AssessmentResponse, status_code=status.HTTP_201_CREATED)
async def create_assessment(
    payload: AssessmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Assessment:
    """Create a new assessment for a child."""
    # Verify child exists
    result = await db.execute(select(Child).where(Child.id == payload.child_id))
    child = result.scalar_one_or_none()
    if not child:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")

    # Parents can only assess their own children
    if current_user.role == UserRole.PARENT and child.parent_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    # Verify instrument exists
    result = await db.execute(
        select(AssessmentInstrument).where(AssessmentInstrument.id == payload.instrument_id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Instrument not found")

    assessment = Assessment(
        child_id=payload.child_id,
        instrument_id=payload.instrument_id,
        assessor_id=current_user.id,
        assessment_type=payload.assessment_type,
        scheduled_at=payload.scheduled_at,
        notes=payload.notes,
    )
    db.add(assessment)
    await db.flush()
    await db.refresh(assessment)
    return assessment


@router.get("/{assessment_id}", response_model=AssessmentResponse)
async def get_assessment(
    assessment_id: uuid.UUID,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Assessment:
    """Retrieve a single assessment by id."""
    result = await db.execute(select(Assessment).where(Assessment.id == assessment_id))
    assessment = result.scalar_one_or_none()
    if not assessment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assessment not found")
    return assessment


@router.patch("/{assessment_id}", response_model=AssessmentResponse)
async def update_assessment(
    assessment_id: uuid.UUID,
    payload: AssessmentUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Assessment:
    """Update an assessment — submit responses, change status, add notes."""
    result = await db.execute(select(Assessment).where(Assessment.id == assessment_id))
    assessment = result.scalar_one_or_none()
    if not assessment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assessment not found")

    update_data = payload.model_dump(exclude_unset=True)

    # Auto-score when responses are submitted
    if "responses" in update_data and update_data["responses"] is not None:
        scores = await _auto_score(db, assessment.instrument_id, update_data["responses"])
        if scores is not None:
            update_data["scores"] = scores

    # Status transitions with timestamps
    new_status = update_data.get("status")
    if new_status == AssessmentStatus.IN_PROGRESS and assessment.started_at is None:
        update_data["started_at"] = datetime.now(timezone.utc)
    elif new_status == AssessmentStatus.COMPLETED:
        update_data["completed_at"] = datetime.now(timezone.utc)
    elif new_status == AssessmentStatus.REVIEWED:
        update_data["reviewed_at"] = datetime.now(timezone.utc)
        if "reviewed_by" not in update_data:
            update_data["reviewed_by"] = current_user.id

    for field, value in update_data.items():
        setattr(assessment, field, value)

    await db.flush()
    await db.refresh(assessment)
    return assessment


# ── Helpers ─────────────────────────────────────────────────────────────────


async def _auto_score(
    db: AsyncSession,
    instrument_id: uuid.UUID,
    responses: dict,
) -> dict | None:
    """Attempt automatic scoring based on instrument slug."""
    result = await db.execute(
        select(AssessmentInstrument).where(AssessmentInstrument.id == instrument_id)
    )
    instrument = result.scalar_one_or_none()
    if not instrument:
        return None

    try:
        if instrument.slug == "cars-2":
            return score_cars2(responses)
        elif instrument.slug.startswith("conners-3"):
            respondent = "parent"
            if "teacher" in instrument.slug:
                respondent = "teacher"
            elif "self" in instrument.slug:
                respondent = "self_report"
            return score_conners3(responses, respondent_type=respondent)
        elif instrument.instrument_type.value == "custom_goal" and instrument.scoring_config:
            return score_custom_goal(responses, instrument.scoring_config)
    except (ValueError, KeyError):
        # If scoring fails, let the caller handle it manually
        return None

    return None


async def _latest_completed(
    db: AsyncSession,
    child_id: uuid.UUID,
    instrument_id: uuid.UUID,
    assessment_type: AssessmentType,
) -> Assessment | None:
    """Return the most recent completed assessment of a given type."""
    result = await db.execute(
        select(Assessment)
        .where(
            Assessment.child_id == child_id,
            Assessment.instrument_id == instrument_id,
            Assessment.assessment_type == assessment_type,
            Assessment.status.in_([AssessmentStatus.COMPLETED, AssessmentStatus.REVIEWED]),
        )
        .order_by(Assessment.completed_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()
