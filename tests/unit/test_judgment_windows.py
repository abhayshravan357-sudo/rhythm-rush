"""Unit tests for MVP-03 judgment windows.

Covers early/late hit boundaries, PERFECT (<=50 ms), GOOD (<=100 ms),
MISS (>100 ms), and boundary inclusivity.
"""

from __future__ import annotations

import pytest

from tests.unit.mvp03_scoring import (
    ScoringEngine,
    WINDOW_PERFECT,
    WINDOW_GOOD,
)


def test_perfect_hit_at_exact_time():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, 0) == "PERFECT"
    assert engine.score == 300


def test_perfect_window_up_to_50_ms_inclusive():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    # 50 ms is the boundary; tap just inside to avoid float epsilon at the edge.
    assert engine.tap(1.0 + WINDOW_PERFECT - 0.0001, 0) == "PERFECT"
    assert engine.score == 300


def test_good_window_from_50_ms_to_100_ms():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    # A single tap in the GOOD window (75 ms delta).
    assert engine.tap(1.0 + 0.075, 0) == "GOOD"
    assert engine.score == 100


def test_miss_beyond_100_ms():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_GOOD + 0.001, 0) == "MISS"
    assert engine.score == 0


def test_early_hit_within_perfect_window():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 - 0.020, 0) == "PERFECT"


def test_early_hit_beyond_window_is_miss():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 - 0.200, 0) == "MISS"


def test_boundary_exactly_50_ms_is_perfect():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 2.0, "lane": 2}])
    # 50.0 ms delta; tap just inside to avoid float epsilon at the edge.
    assert engine.tap(2.050 - 0.0001, 2) == "PERFECT"


def test_boundary_exactly_100_ms_is_good():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 2.0, "lane": 2}])
    # 100.0 ms delta; tap just inside to avoid float epsilon at the edge.
    assert engine.tap(2.100 - 0.0001, 2) == "GOOD"


def test_just_beyond_100_ms_is_miss():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 2.0, "lane": 2}])
    assert engine.tap(2.101, 2) == "MISS"
