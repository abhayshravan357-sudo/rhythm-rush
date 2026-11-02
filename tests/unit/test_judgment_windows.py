"""Unit tests for judgment-window boundaries (PERFECT/GOOD/MISS).

Uses the calibrated ScoringEngine reference (PERFECT <= 50 ms, GOOD <= 100 ms,
no OK tier) matching the MVP acceptance criteria.
"""

from __future__ import annotations

from tests.unit.scoring_engine import (
    ScoringEngine,
    WINDOW_GOOD,
    WINDOW_PERFECT,
)


def test_perfect_window_includes_zero_and_50_ms_boundary():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, 0) == "PERFECT"
    # Already resolved -> duplicate hit is a no-op.
    assert engine.tap(1.0, 0) is None


def test_perfect_window_up_to_50_ms_inclusive():
    # 49 ms -> PERFECT on a fresh note.
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}])
    assert engine.tap(WINDOW_PERFECT - 0.001, 0) == "PERFECT"
    # 50 ms (boundary inclusive) -> PERFECT on a fresh note.
    engine2 = ScoringEngine()
    engine2.reset([{"timestamp": 0.0, "lane": 0}])
    assert engine2.tap(WINDOW_PERFECT, 0) == "PERFECT"


def test_good_window_from_50_to_100_ms_inclusive():
    # 50.001 ms -> GOOD on a fresh note.
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}])
    assert engine.tap(WINDOW_PERFECT + 0.001, 0) == "GOOD"
    # 100 ms (boundary inclusive) -> GOOD on a fresh note.
    engine2 = ScoringEngine()
    engine2.reset([{"timestamp": 0.0, "lane": 0}])
    assert engine2.tap(WINDOW_GOOD, 0) == "GOOD"


def test_miss_beyond_100_ms():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}])
    rating = engine.tap(WINDOW_GOOD + 0.001, 0)
    assert rating == "MISS"
    assert engine.score == 0
    assert engine.resolved_count == 1  # miss still resolves the note


def test_invalid_lane_returns_none():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, -1) is None
    assert engine.tap(1.0, 99) is None
    assert engine.resolved_count == 0
    assert engine.score == 0
