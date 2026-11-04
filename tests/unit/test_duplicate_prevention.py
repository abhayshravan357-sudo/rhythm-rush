"""Unit tests for MVP-03 duplicate-hit prevention.

Covers: same note hit twice, note resolved by miss cannot be re-hit,
each note counted exactly once, no duplicate scoring.
"""

from __future__ import annotations

from tests.unit.mvp03_scoring import ScoringEngine


def test_duplicate_hit_on_same_note_is_noop():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    first = engine.tap(1.0, 0)
    assert first == "PERFECT"
    score_after = engine.score
    combo_after = engine.combo
    resolved_after = engine.resolved_count

    second = engine.tap(1.0, 0)  # same note, already resolved
    assert second is None
    assert engine.score == score_after
    assert engine.combo == combo_after
    assert engine.resolved_count == resolved_after


def test_duplicate_hit_after_miss_is_noop():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    engine.register_miss(0)
    assert engine.resolved_count == 1
    assert engine.tap(1.0, 0) is None  # already resolved by miss
    assert engine.resolved_count == 1
    assert engine.miss_count == 1


def test_each_note_counted_once_max_score():
    engine = ScoringEngine()
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 0.0, "lane": 0},
        ]
    )
    engine.tap(0.0, 0)
    engine.tap(0.0, 0)  # second unresolved note at same timestamp/lane
    assert engine.resolved_count == 2
    assert engine.score == 600  # 2 * PERFECT(300)


def test_tap_on_already_resolved_note_does_not_change_combo():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    engine.tap(1.0, 0)
    combo_after_first = engine.combo
    engine.tap(1.0, 0)  # duplicate
    assert engine.combo == combo_after_first


def test_invalid_lane_tap_ignored_no_resolution():
    engine = ScoringEngine()
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, -1) is None
    assert engine.tap(1.0, 4) is None  # LANE_COUNT = 4
    assert engine.resolved_count == 0
    assert engine.score == 0
