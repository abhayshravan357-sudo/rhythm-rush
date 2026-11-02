"""Unit tests for MVP-03 accuracy calculation.

Covers judgment-based accuracy, empty chart, all-perfect, all-miss,
and grade bands.
"""

from __future__ import annotations

import pytest

from tests.unit.mvp03_scoring import ScoringEngine


def test_accuracy_zero_for_empty_chart():
    engine = ScoringEngine()
    engine.reset([])
    assert engine.accuracy == 0.0


def test_accuracy_all_perfect_is_100():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}, {"timestamp": 1.0, "lane": 1}])
    engine.tap(0.0, 0)
    engine.tap(1.0, 1)
    assert engine.accuracy == pytest.approx(100.0)


def test_accuracy_all_miss_is_zero():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}, {"timestamp": 2.0, "lane": 1}])
    engine.tap(0.0 + 0.200, 0)  # MISS
    engine.tap(2.0 + 0.200, 1)  # MISS
    assert engine.accuracy == pytest.approx(0.0)


def test_accuracy_mixed_judgments():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},  # PERFECT -> 300
            {"timestamp": 1.0, "lane": 1},  # GOOD -> 100
            {"timestamp": 2.0, "lane": 2},  # MISS -> 0
        ]
    )
    engine.tap(0.0, 0)          # PERFECT
    engine.tap(1.0 + 0.075, 1)  # GOOD (75 ms)
    engine.tap(2.0 + 0.200, 2)  # MISS
    # earned = 300 + 100 + 0 = 400; max = 3 * 300 = 900; acc = 400/900*100
    assert engine.accuracy == pytest.approx(400.0 / 900.0 * 100.0)


def test_accuracy_clamped_to_100():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 0.0, "lane": 0}])
    engine.tap(0.0, 0)
    assert engine.accuracy <= 100.0


def test_grade_bands():
    cases = [
        (100.0, "S"),
        (95.0, "S"),
        (94.0, "A"),
        (90.0, "A"),
        (89.0, "B"),
        (80.0, "B"),
        (79.0, "C"),
        (70.0, "C"),
        (69.0, "D"),
        (60.0, "D"),
        (59.0, "F"),
        (0.0, "F"),
    ]
    for acc, expected in cases:
        engine = ScoringEngine()
        total = 100
        engine.reset([{"timestamp": 0.0, "lane": 0}] * total)
        resolved = int(round(acc / 100.0 * total))
        # Resolve `resolved` notes as PERFECT, rest as MISS
        for i in range(resolved):
            engine.tap(0.0, 0)
        for i in range(resolved, total):
            engine.register_miss(i)
        assert engine.grade() == expected, f"accuracy {acc} -> {engine.grade()}, expected {expected}"
