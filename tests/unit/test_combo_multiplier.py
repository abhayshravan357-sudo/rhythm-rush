"""Unit tests for MVP-03 combo and score multiplier.

Covers multiplier tiers (1x/2x/3x/4x), points = base * multiplier,
max multiplier cap, and combo tracking.
"""

from __future__ import annotations

from tests.unit.mvp03_scoring import (
    ScoringEngine,
    WINDOW_PERFECT,
    WINDOW_GOOD,
    MAX_MULTIPLIER,
    COMBO_TIER_STEP,
)


def test_multiplier_starts_at_one():
    engine = ScoringEngine()
    assert engine.get_multiplier() == 1


def test_multiplier_tiers_by_combo():
    engine = ScoringEngine()
    engine.reset([{"timestamp": float(i), "lane": i % 4} for i in range(40)])
    # Tap each note perfectly in order to build combo 1..40
    for i in range(40):
        engine.tap(float(i), i % 4)
        expected_combo = i + 1
        expected_mult = max(1, min(1 + (expected_combo // COMBO_TIER_STEP), MAX_MULTIPLIER))
        assert engine.combo == expected_combo
        assert engine.get_multiplier() == expected_mult


def test_multiplier_capped_at_max():
    engine = ScoringEngine()
    engine.reset([{"timestamp": float(i), "lane": i % 4} for i in range(100)])
    for i in range(100):
        engine.tap(float(i), i % 4)
    assert engine.get_multiplier() == MAX_MULTIPLIER
    assert engine.combo == 100


def test_points_use_multiplier():
    engine = ScoringEngine()
    engine.reset([{"timestamp": float(i), "lane": i % 4} for i in range(40)])
    # Build combo to 10 via notes 0-9 (timestamps 0-9, lanes 0,1,2,3,0,1,2,3,0,1).
    for i in range(10):
        engine.tap(float(i), i % 4)
    assert engine.combo == 10
    assert engine.get_multiplier() == 2
    # Next perfect hit: note 10 at timestamp 10.0, lane 2. Combo -> 11, mult 2.
    engine.tap(10.0, 2)
    assert engine.combo == 11
    # Notes 0-8: combo 1-9, mult 1 -> 9 * 300 = 2700.
    # Note 9: combo 10, mult 2 -> 600.
    # Note 10: combo 11, mult 2 -> 600.
    # Total = 3900.
    assert engine.score == 3900


def test_miss_resets_combo_and_multiplier():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}, {"timestamp": 2.0, "lane": 1}])
    engine.tap(0.0, 0)
    assert engine.combo == 1
    assert engine.get_multiplier() == 1
    # Second note: tap late (MISS) -> combo resets to 0, multiplier back to 1
    engine.tap(2.0 + WINDOW_GOOD + 0.001, 1)
    assert engine.combo == 0
    assert engine.get_multiplier() == 1


def test_max_multiplier_never_exceeds_cap():
    engine = ScoringEngine()
    engine.reset([{"timestamp": float(i), "lane": i % 4} for i in range(200)])
    for i in range(200):
        engine.tap(float(i), i % 4)
    assert engine.get_multiplier() <= MAX_MULTIPLIER
