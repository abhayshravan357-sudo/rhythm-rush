"""Unit tests for accuracy percentage calculation.

Accuracy is the fraction of resolved notes over total notes; misses still
count as resolved, so an all-miss playthrough yields 100% accuracy.
"""

from __future__ import annotations

from tests.unit.scoring_engine import ScoringEngine


def test_accuracy_ratio_resolved_over_total():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    engine.tap(0.0, 0)
    assert engine.accuracy == 1 / 3
    engine.tap(1.0, 1)
    assert engine.accuracy == 2 / 3
    engine.tap(2.0, 2)
    assert engine.accuracy == 1.0


def test_accuracy_zero_for_empty_chart():
    engine = ScoringEngine()
    engine.reset([])
    assert engine.accuracy == 0.0


def test_accuracy_counts_misses_as_resolved():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
        ]
    )
    engine.tap(0.0 + 0.2, 0)  # MISS
    engine.tap(1.0 + 0.2, 1)  # MISS
    assert engine.accuracy == 1.0  # both notes resolved as misses


def test_accuracy_all_perfect_is_one():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}, {"timestamp": 1.0, "lane": 1}])
    engine.tap(0.0, 0)
    engine.tap(1.0, 1)
    assert engine.accuracy == 1.0
