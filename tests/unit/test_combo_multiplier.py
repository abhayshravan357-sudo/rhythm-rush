"""Unit tests for combo counter and max-combo tracking (combo multiplier).

Consecutive hits increment the combo; a miss resets it to zero; max_combo
records the peak combo reached during the playthrough.
"""

from __future__ import annotations

from tests.unit.scoring_engine import ScoringEngine, WINDOW_GOOD


def test_combo_increments_on_consecutive_hits():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    engine.tap(0.0, 0)
    assert engine.combo == 1
    engine.tap(1.0, 1)
    assert engine.combo == 2
    engine.tap(2.0, 2)
    assert engine.combo == 3
    assert engine.max_combo == 3


def test_miss_resets_combo_to_zero():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
        ]
    )
    engine.tap(0.0, 0)
    assert engine.combo == 1
    engine.tap(1.0 + WINDOW_GOOD + 0.001, 1)  # MISS
    assert engine.combo == 0
    assert engine.max_combo == 1


def test_max_combo_tracks_peak_after_miss():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
            {"timestamp": 3.0, "lane": 3},
        ]
    )
    engine.tap(0.0, 0)  # combo 1
    engine.tap(1.0 + WINDOW_GOOD + 0.001, 1)  # MISS -> combo 0
    engine.tap(2.0, 2)  # combo 1
    engine.tap(3.0, 3)  # combo 2
    assert engine.combo == 2
    assert engine.max_combo == 2


def test_combo_zero_for_empty_chart():
    engine = ScoringEngine()
    engine.reset([])
    assert engine.combo == 0
    assert engine.max_combo == 0
