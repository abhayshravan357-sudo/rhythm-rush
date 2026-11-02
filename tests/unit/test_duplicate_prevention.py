"""Unit tests for duplicate-hit prevention.

A note may be resolved only once; repeated taps on an already-resolved note
must be no-ops that do not change score, combo, or resolved count.
"""

from __future__ import annotations

from tests.unit.scoring_engine import ScoringEngine, WINDOW_GOOD


def test_duplicate_hit_on_same_note_is_noop():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    first = engine.tap(1.0, 0)
    assert first == "PERFECT"
    score_after_first = engine.score
    combo_after_first = engine.combo
    resolved_after_first = engine.resolved_count

    second = engine.tap(1.0, 0)  # same note, already resolved
    assert second is None
    assert engine.score == score_after_first
    assert engine.combo == combo_after_first
    assert engine.resolved_count == resolved_after_first


def test_duplicate_hit_after_miss_is_noop():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    engine.tap(1.0 + WINDOW_GOOD + 0.001, 0)  # MISS, resolves the note
    assert engine.resolved_count == 1
    assert engine.tap(1.0, 0) is None  # already resolved by miss
    assert engine.resolved_count == 1


def test_each_note_counted_once_max_score():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 0.0, "lane": 0},
        ]
    )
    engine.tap(0.0, 0)
    engine.tap(0.0, 0)  # second unresolved note at same time/lane
    assert engine.resolved_count == 2
    assert engine.score == 600  # 2 * 300


def test_invalid_lane_duplicate_ignored():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, -1) is None
    assert engine.tap(1.0, 99) is None
    assert engine.resolved_count == 0
    assert engine.score == 0
