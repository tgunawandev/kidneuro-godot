"""Adaptive difficulty engine - adjusts game difficulty based on child performance."""

from sqlalchemy import and_, select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from kidneuro.models.child import Child, ChildDiagnosis
from kidneuro.models.game import Game
from kidneuro.models.session import TherapySession, SessionStatus


class DifficultyEngine:
    """Computes recommended difficulty based on recent performance.

    The algorithm uses exponential moving averages of accuracy and response-time
    trends, weighted by game category, then dampened by diagnosis sensitivity to
    avoid rapid oscillation -- especially important for children on the spectrum.
    """

    # Weight profiles per game category
    WEIGHT_PROFILES: dict[str, dict[str, float]] = {
        "attention_focus": {"accuracy": 0.4, "response_time": 0.4, "trend": 0.2},
        "emotional_regulation": {"accuracy": 0.6, "response_time": 0.1, "trend": 0.3},
        "social_skills": {"accuracy": 0.5, "response_time": 0.15, "trend": 0.35},
        "executive_function": {"accuracy": 0.35, "response_time": 0.35, "trend": 0.3},
        "sensory_processing": {"accuracy": 0.3, "response_time": 0.2, "trend": 0.5},
        "communication": {"accuracy": 0.5, "response_time": 0.2, "trend": 0.3},
        "cognitive": {"accuracy": 0.45, "response_time": 0.3, "trend": 0.25},
        "default": {"accuracy": 0.4, "response_time": 0.3, "trend": 0.3},
    }

    # Diagnosis sensitivity multipliers (lower = more conservative adjustments)
    DIAGNOSIS_SENSITIVITY: dict[ChildDiagnosis, float] = {
        ChildDiagnosis.ASD: 0.7,
        ChildDiagnosis.ADHD: 0.85,
        ChildDiagnosis.ASD_ADHD: 0.6,
        ChildDiagnosis.OTHER: 0.8,
        ChildDiagnosis.UNDIAGNOSED: 1.0,
    }

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    @classmethod
    async def recommend(
        cls,
        db: AsyncSession,
        child_id,
        game_id,
        lookback_sessions: int = 10,
    ) -> dict:
        """Return recommended difficulty and reasoning for *child_id* playing *game_id*.

        Parameters
        ----------
        db:
            Active async database session.
        child_id:
            UUID of the child.
        game_id:
            UUID of the game.
        lookback_sessions:
            Maximum number of recent completed sessions to consider (5-10 typical).

        Returns
        -------
        dict with ``recommended_level``, ``current_level``, ``confidence``,
        ``reasoning``, and ``metrics``.
        """

        # ------ Fetch child for diagnosis sensitivity ------
        child_result = await db.execute(select(Child).where(Child.id == child_id))
        child = child_result.scalar_one_or_none()
        if not child:
            return {
                "recommended_level": 1,
                "confidence": 0.0,
                "reasoning": "Child not found",
                "metrics": {},
            }

        # ------ Fetch recent completed sessions for this game ------
        sessions_q = (
            select(TherapySession)
            .where(
                and_(
                    TherapySession.child_id == child_id,
                    TherapySession.game_id == game_id,
                    TherapySession.status == SessionStatus.COMPLETED,
                    TherapySession.accuracy.isnot(None),
                )
            )
            .order_by(desc(TherapySession.started_at))
            .limit(lookback_sessions)
        )
        result = await db.execute(sessions_q)
        sessions = list(result.scalars().all())

        if not sessions:
            return {
                "recommended_level": 1,
                "current_level": None,
                "confidence": 0.0,
                "reasoning": "No completed sessions found, starting at level 1",
                "metrics": {},
            }

        current_level = sessions[0].difficulty_level

        # ------ Calculate metrics ------
        accuracies = [s.accuracy for s in sessions if s.accuracy is not None]
        response_times = [
            s.avg_response_time_ms for s in sessions if s.avg_response_time_ms is not None
        ]

        # Exponential moving average for accuracy
        avg_accuracy = cls._ema(accuracies)

        # Trend: compare recent half vs older half
        mid = max(1, len(accuracies) // 2)
        recent_acc = sum(accuracies[:mid]) / mid
        older_acc = (
            sum(accuracies[mid:]) / max(1, len(accuracies) - mid)
            if len(accuracies) > mid
            else recent_acc
        )
        accuracy_trend = recent_acc - older_acc  # positive = improving

        # Response-time trend (lower is better, so positive = improving/faster)
        rt_trend = 0.0
        if len(response_times) >= 2:
            rt_mid = max(1, len(response_times) // 2)
            recent_rt = sum(response_times[:rt_mid]) / rt_mid
            older_rt = (
                sum(response_times[rt_mid:]) / max(1, len(response_times) - rt_mid)
                if len(response_times) > rt_mid
                else recent_rt
            )
            rt_trend = (older_rt - recent_rt) / max(older_rt, 1)  # positive = faster

        # ------ Resolve game category for weight profile ------
        game_obj = await db.execute(select(Game).where(Game.id == game_id))
        game = game_obj.scalar_one_or_none()
        category = game.category.value if game else "default"
        weights = cls.WEIGHT_PROFILES.get(category, cls.WEIGHT_PROFILES["default"])

        # ------ Score components (-1 to +1 scale) ------
        # 0.65 is the neutral accuracy point; above is positive, below is negative
        accuracy_score = max(-1.0, min(1.0, (avg_accuracy - 0.65) / 0.35))
        rt_score = max(-1.0, min(1.0, rt_trend * 2))
        trend_score = max(-1.0, min(1.0, accuracy_trend * 5))

        # Weighted composite
        composite = (
            weights["accuracy"] * accuracy_score
            + weights["response_time"] * rt_score
            + weights["trend"] * trend_score
        )

        # Apply diagnosis sensitivity
        sensitivity = cls.DIAGNOSIS_SENSITIVITY.get(child.diagnosis, 1.0)
        adjustment = composite * sensitivity

        # Dampen change to avoid oscillation (max +/-1 level per recommendation)
        if adjustment > 0.3:
            delta = 1
        elif adjustment < -0.3:
            delta = -1
        else:
            delta = 0

        recommended = max(1, min(10, current_level + delta))
        confidence = min(1.0, len(sessions) / lookback_sessions)

        # ------ Build human-readable reasoning ------
        reasons: list[str] = []
        if avg_accuracy >= 0.85:
            reasons.append(f"High accuracy ({avg_accuracy:.0%})")
        elif avg_accuracy < 0.5:
            reasons.append(f"Low accuracy ({avg_accuracy:.0%})")
        if accuracy_trend > 0.05:
            reasons.append("Improving trend")
        elif accuracy_trend < -0.05:
            reasons.append("Declining trend")
        if rt_trend > 0.1:
            reasons.append("Faster responses")
        elif rt_trend < -0.1:
            reasons.append("Slower responses")

        reasoning = "; ".join(reasons) if reasons else "Performance is stable"
        if delta > 0:
            reasoning = f"Increase difficulty: {reasoning}"
        elif delta < 0:
            reasoning = f"Decrease difficulty: {reasoning}"
        else:
            reasoning = f"Maintain difficulty: {reasoning}"

        return {
            "recommended_level": recommended,
            "current_level": current_level,
            "confidence": round(confidence, 2),
            "reasoning": reasoning,
            "metrics": {
                "avg_accuracy": round(avg_accuracy, 3),
                "accuracy_trend": round(accuracy_trend, 3),
                "rt_trend": round(rt_trend, 3),
                "composite_score": round(composite, 3),
                "sessions_analyzed": len(sessions),
                "sensitivity": sensitivity,
            },
        }

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _ema(values: list[float], alpha: float = 0.3) -> float:
        """Exponential moving average where *values[0]* is the most recent.

        A higher ``alpha`` gives more weight to each successive older value as
        it is folded in, effectively smoothing out short-term noise.
        """
        if not values:
            return 0.0
        result = values[-1]
        for v in reversed(values[:-1]):
            result = alpha * v + (1 - alpha) * result
        return result
