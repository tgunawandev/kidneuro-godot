"""Assessment scoring engines — CARS-2, Conners-3, custom goals, and pre/post comparison."""

from __future__ import annotations

import math
from typing import Any


# ── CARS-2 (Childhood Autism Rating Scale, 2nd Edition) ─────────────────────
#
# 15 items rated 1-4 (half-point increments allowed).
# Total range: 15-60.
# Severity cutoffs (Standard Version):
#   < 30  → Minimal-to-no symptoms
#   30-36 → Mild-to-moderate ASD symptoms
#   ≥ 37  → Severe ASD symptoms

CARS2_ITEMS = 15
CARS2_SCALE_MIN = 1.0
CARS2_SCALE_MAX = 4.0
CARS2_CUTOFF_MILD = 30.0
CARS2_CUTOFF_SEVERE = 37.0


def score_cars2(responses: dict[str, float | int]) -> dict[str, Any]:
    """Score a CARS-2 assessment from item responses.

    Args:
        responses: Mapping of item id (str) → rating (1.0-4.0).

    Returns:
        Dict with total score, severity label, and per-item breakdown.
    """
    values: list[float] = []
    def _sort_key(k: str) -> tuple[int, str]:
        try:
            return (0, str(int(k)).zfill(10))
        except (ValueError, TypeError):
            return (1, k)

    for item_key in sorted(responses.keys(), key=_sort_key):
        val = float(responses[item_key])
        if val < CARS2_SCALE_MIN or val > CARS2_SCALE_MAX:
            raise ValueError(
                f"Item {item_key}: value {val} outside range "
                f"[{CARS2_SCALE_MIN}, {CARS2_SCALE_MAX}]"
            )
        values.append(val)

    if len(values) != CARS2_ITEMS:
        raise ValueError(f"CARS-2 requires {CARS2_ITEMS} items, got {len(values)}")

    total = sum(values)

    if total < CARS2_CUTOFF_MILD:
        severity = "minimal"
    elif total < CARS2_CUTOFF_SEVERE:
        severity = "mild_moderate"
    else:
        severity = "severe"

    return {
        "total": round(total, 1),
        "severity": severity,
        "item_count": len(values),
        "mean_item_score": round(total / len(values), 2),
    }


# ── Conners-3 ───────────────────────────────────────────────────────────────
#
# Subscales scored as raw totals then converted to T-scores via normative
# lookup tables (approximated here as linear transforms per respondent type).
# T-score interpretation:
#   < 60      → Average (within normal limits)
#   60-64     → High Average (slightly elevated)
#   65-69     → Elevated
#   ≥ 70      → Very Elevated (clinically significant)

CONNERS3_SUBSCALES: dict[str, list[str]] = {
    "inattention": [str(i) for i in range(1, 11)],        # items 1-10
    "hyperactivity": [str(i) for i in range(11, 21)],      # items 11-20
    "learning_problems": [str(i) for i in range(21, 27)],  # items 21-26
    "executive_function": [str(i) for i in range(27, 36)],  # items 27-35
    "aggression": [str(i) for i in range(36, 46)],          # items 36-45
    "peer_relations": [str(i) for i in range(46, 52)],      # items 46-51
}

# Simplified normative conversion parameters (mean, sd) by respondent type.
# In production these would come from published normative tables by age/gender.
_CONNERS3_NORMS: dict[str, dict[str, tuple[float, float]]] = {
    "parent": {
        "inattention": (12.0, 5.5),
        "hyperactivity": (10.0, 6.0),
        "learning_problems": (5.0, 3.5),
        "executive_function": (8.0, 4.5),
        "aggression": (6.0, 5.0),
        "peer_relations": (4.0, 3.0),
    },
    "teacher": {
        "inattention": (10.0, 6.0),
        "hyperactivity": (8.0, 5.5),
        "learning_problems": (4.0, 3.0),
        "executive_function": (7.0, 4.0),
        "aggression": (5.0, 4.5),
        "peer_relations": (3.5, 2.8),
    },
    "self_report": {
        "inattention": (14.0, 5.0),
        "hyperactivity": (12.0, 5.5),
        "learning_problems": (6.0, 3.0),
        "executive_function": (9.0, 4.0),
        "aggression": (7.0, 4.5),
        "peer_relations": (5.0, 3.0),
    },
}


def _raw_to_tscore(raw: float, norm_mean: float, norm_sd: float) -> int:
    """Convert raw score to T-score (mean=50, sd=10) using normative z-transform."""
    if norm_sd == 0:
        return 50
    z = (raw - norm_mean) / norm_sd
    t = 50 + 10 * z
    return max(20, min(90, round(t)))


def _t_severity(t: int) -> str:
    if t < 60:
        return "average"
    if t < 65:
        return "high_average"
    if t < 70:
        return "elevated"
    return "very_elevated"


def score_conners3(
    responses: dict[str, int],
    respondent_type: str = "parent",
) -> dict[str, Any]:
    """Score a Conners-3 assessment.

    Args:
        responses: Mapping of item id (str) → rating (0-3).
        respondent_type: One of 'parent', 'teacher', 'self_report'.

    Returns:
        Dict with subscale raw scores, T-scores, severity labels, and total index.
    """
    norms = _CONNERS3_NORMS.get(respondent_type)
    if norms is None:
        raise ValueError(
            f"Unknown respondent_type '{respondent_type}'. "
            f"Expected one of: {list(_CONNERS3_NORMS.keys())}"
        )

    subscales: dict[str, Any] = {}
    total_t: list[int] = []

    for scale_name, item_ids in CONNERS3_SUBSCALES.items():
        raw = sum(int(responses.get(iid, 0)) for iid in item_ids)
        norm_mean, norm_sd = norms[scale_name]
        t = _raw_to_tscore(raw, norm_mean, norm_sd)
        total_t.append(t)
        subscales[scale_name] = {
            "raw": raw,
            "t_score": t,
            "severity": _t_severity(t),
        }

    global_index = round(sum(total_t) / len(total_t)) if total_t else 50

    return {
        "subscales": subscales,
        "global_index": global_index,
        "global_severity": _t_severity(global_index),
        "respondent_type": respondent_type,
    }


# ── Custom Goal Scoring ────────────────────────────────────────────────────


def score_custom_goal(
    responses: dict[str, Any],
    config: dict[str, Any],
) -> dict[str, Any]:
    """Score a custom goal-based assessment using a configurable schema.

    Config structure example:
        {
            "goals": [
                {"id": "g1", "name": "Eye contact", "max_score": 5, "weight": 1.0},
                {"id": "g2", "name": "Turn-taking", "max_score": 5, "weight": 1.5},
            ]
        }

    Responses: {"g1": 3, "g2": 4}
    """
    goals = config.get("goals", [])
    if not goals:
        raise ValueError("scoring_config must contain a 'goals' list")

    goal_scores: list[dict[str, Any]] = []
    weighted_sum = 0.0
    weight_total = 0.0
    raw_sum = 0
    max_possible = 0

    for goal in goals:
        gid = str(goal["id"])
        raw = int(responses.get(gid, 0))
        max_score = int(goal.get("max_score", 5))
        weight = float(goal.get("weight", 1.0))

        pct = (raw / max_score * 100) if max_score > 0 else 0.0
        weighted_sum += raw * weight
        weight_total += max_score * weight
        raw_sum += raw
        max_possible += max_score

        goal_scores.append({
            "goal_id": gid,
            "name": goal.get("name", gid),
            "raw": raw,
            "max": max_score,
            "pct": round(pct, 1),
        })

    overall_pct = (weighted_sum / weight_total * 100) if weight_total > 0 else 0.0

    return {
        "goals": goal_scores,
        "total_raw": raw_sum,
        "total_max": max_possible,
        "weighted_pct": round(overall_pct, 1),
    }


# ── Pre / Post Comparison (effect size + reliable change) ──────────────────


def compute_comparison(
    pre_scores: dict[str, Any],
    post_scores: dict[str, Any],
    test_retest_reliability: float = 0.85,
    normative_sd: float | None = None,
) -> dict[str, Any]:
    """Compute outcome statistics between pre and post assessment scores.

    Calculates:
        - Raw change for each matching score key
        - Cohen's d effect size (if normative SD provided)
        - Reliable Change Index (RCI) to test whether change exceeds measurement error

    Args:
        pre_scores: Scores dict from the pre assessment.
        post_scores: Scores dict from the post assessment.
        test_retest_reliability: r_xx for the instrument (default 0.85).
        normative_sd: Population SD used for Cohen's d; if None, d is skipped.

    Returns:
        Dict with change details, effect_size, rci, and clinical significance flag.
    """
    # Find the primary numeric score to compare
    pre_total = _extract_primary_score(pre_scores)
    post_total = _extract_primary_score(post_scores)

    if pre_total is None or post_total is None:
        return {
            "score_change": None,
            "effect_size": None,
            "reliable_change_index": None,
            "clinically_significant": None,
            "detail": "Could not extract comparable numeric scores",
        }

    raw_change = post_total - pre_total

    # Standard error of measurement: SE_m = SD * sqrt(1 - r_xx)
    sd = normative_sd if normative_sd else _estimate_sd(pre_total, post_total)
    se_m = sd * math.sqrt(1 - test_retest_reliability) if sd > 0 else 0

    # Standard error of the difference: SE_diff = sqrt(2 * SE_m^2)
    se_diff = math.sqrt(2 * se_m**2) if se_m > 0 else 0

    # Reliable Change Index
    rci = (raw_change / se_diff) if se_diff > 0 else 0.0

    # Cohen's d (negative = improvement for symptom scales)
    effect_size: float | None = None
    if normative_sd and normative_sd > 0:
        effect_size = round(raw_change / normative_sd, 3)

    # RCI ≥ 1.96 (or ≤ -1.96) indicates statistically reliable change (p < .05)
    clinically_significant = abs(rci) >= 1.96

    return {
        "score_change": {
            "pre": pre_total,
            "post": post_total,
            "raw_change": round(raw_change, 2),
            "pct_change": round(raw_change / pre_total * 100, 1) if pre_total != 0 else 0,
        },
        "effect_size": effect_size,
        "reliable_change_index": round(rci, 3),
        "clinically_significant": clinically_significant,
    }


def _extract_primary_score(scores: dict[str, Any]) -> float | None:
    """Pull the primary numeric value from a scores dict."""
    # Try common keys in order of preference
    for key in ("total", "weighted_pct", "global_index"):
        if key in scores and scores[key] is not None:
            return float(scores[key])
    # Fall back to first numeric value
    for v in scores.values():
        if isinstance(v, (int, float)):
            return float(v)
    return None


def _estimate_sd(a: float, b: float) -> float:
    """Rough SD estimate from two data points (used when normative SD not available)."""
    mean = (a + b) / 2
    return math.sqrt(((a - mean) ** 2 + (b - mean) ** 2) / 2)
