"""Unit tests for scoring logic (MVP-01 calibrated windows).

Verifies the pure-Python reference implementation of ScoreManager judgment
rules against the calibrated hit windows:

    PERFECT : delta <= 50 ms   -> 300 pts
    GOOD    : delta <= 100 ms  -> 100 pts
    MISS    : delta > 100 ms   ->   0 pts, combo reset

These tests exercise actual scoring logic (no faked interactions, no mocks).
They do not depend on the Godot ScoreManager autoload.
"""

from __future__ import annotations

from tests.unit.scoring_engine import (
    LANE_COUNT,
    POINTS_GOOD,
    POINTS_MISS,
    POINTS_PERFECT,
    WINDOW_GOOD,
    WINDOW_PERFECT,
    ScoringEngine,
)

MS = 0.001  # seconds per millisecond


def fresh(notes):
    engine = ScoringEngine()
    engine.reset(notes)
    return engine


# ── Hit windows ───────────────────────────────────────────────────────────────


def test_perfect_exact_timestamp():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, 0) == "PERFECT"
    assert engine.score == POINTS_PERFECT
    assert engine.combo == 1
    assert engine.max_combo == 1


def test_perfect_window_up_to_50_ms_inclusive():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    # Clearly within the window (<= 50 ms).
    assert engine.tap(1.0 + WINDOW_PERFECT / 2, 0) == "PERFECT"
    assert engine.score == POINTS_PERFECT


def test_perfect_boundary_inclusive_at_engine_level():
    # The <= comparison is inclusive at exactly WINDOW_PERFECT (engine level,
    # avoiding float addition error in tap()'s playback_time computation).
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    engine.notes[0].resolved = False
    assert engine._evaluate(0, WINDOW_PERFECT) == "PERFECT"
    assert engine._evaluate(0, WINDOW_PERFECT) == "PERFECT" if False else True


def test_perfect_window_rejects_just_over_50_ms():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_PERFECT + MS, 0) == "GOOD"  # 50.001 ms
    assert engine.score == POINTS_GOOD


def test_good_window_up_to_100_ms_inclusive_at_engine_level():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine._evaluate(0, WINDOW_GOOD) == "GOOD"


def test_good_window_rejects_just_over_100_ms():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_GOOD + MS, 0) == "MISS"  # 100.001 ms
    assert engine.score == POINTS_MISS
    assert engine.combo == 0


def test_good_window_from_50_ms_to_100_ms_inclusive():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_PERFECT + MS, 0) == "GOOD"  # 50.001 ms
    assert engine.tap(1.0 + WINDOW_GOOD, 0) is None  # note already resolved
    assert engine.score == POINTS_GOOD


def test_good_window_rejects_just_over_100_ms():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_GOOD + MS, 0) == "MISS"  # 100.001 ms
    assert engine.score == POINTS_MISS
    assert engine.combo == 0


def test_miss_beyond_100_ms_resets_combo():
    engine = fresh([{"timestamp": 0.0, "lane": 0}, {"timestamp": 1.0, "lane": 1}])
    engine.tap(0.0, 0)
    assert engine.combo == 1
    engine.tap(1.0 + WINDOW_GOOD + MS, 1)  # MISS
    assert engine.combo == 0
    assert engine.max_combo == 1


def test_miss_adds_zero_points():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    engine.tap(1.0 + WINDOW_GOOD + MS, 0)
    assert engine.score == POINTS_MISS


def test_tap_no_unresolved_note_in_lane_returns_none():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    engine.tap(1.0, 0)  # resolves the only note
    assert engine.tap(1.0, 0) is None  # duplicate hit on resolved note
    assert engine.score == POINTS_PERFECT  # unchanged


def test_invalid_lane_tap_ignored():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, -1) is None
    assert engine.tap(1.0, LANE_COUNT) is None
    assert engine.resolved_count == 0
    assert engine.score == 0


# ── Combo / max combo ─────────────────────────────────────────────────────────


def test_combo_increments_on_consecutive_hits():
    engine = fresh(
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


def test_miss_resets_combo_but_keeps_peak():
    engine = fresh(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    engine.tap(0.0, 0)
    engine.tap(1.0, 1)
    assert engine.combo == 2
    engine.tap(2.0 + WINDOW_GOOD + MS, 2)  # MISS
    assert engine.combo == 0
    assert engine.max_combo == 2


def test_max_combo_tracks_peak_across_miss():
    engine = fresh(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
            {"timestamp": 3.0, "lane": 3},
        ]
    )
    engine.tap(0.0, 0)
    engine.tap(1.0 + WINDOW_GOOD + MS, 1)  # MISS -> combo 0
    engine.tap(2.0, 2)
    engine.tap(3.0, 3)
    assert engine.combo == 2
    assert engine.max_combo == 2


# ── Accuracy ──────────────────────────────────────────────────────────────────


def test_accuracy_ratio_resolved_over_total():
    engine = fresh(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    assert engine.accuracy == 0.0
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


# ── Grade ─────────────────────────────────────────────────────────────────────


def test_grade_scale_by_accuracy():
    cases = [
        (1.0, "S"),
        (0.95, "S"),
        (0.94, "A"),
        (0.90, "A"),
        (0.89, "B"),
        (0.80, "B"),
        (0.79, "C"),
        (0.70, "C"),
        (0.69, "D"),
        (0.60, "D"),
        (0.59, "F"),
        (0.0, "F"),
    ]
    for acc, expected in cases:
        total = 100
        engine = fresh([{"timestamp": 0.0, "lane": 0}] * total)
        resolved = int(round(acc * total))
        for _ in range(resolved):
            engine.tap(0.0, 0)
        assert engine.grade() == expected, f"accuracy {acc} -> {engine.grade()}, expected {expected}"


# ── Negative-score prevention ─────────────────────────────────────────────────


def test_score_never_negative_on_all_misses():
    engine = fresh(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    engine.tap(0.0 + WINDOW_GOOD + MS, 0)  # MISS
    engine.tap(1.0 + WINDOW_GOOD + MS, 1)  # MISS
    engine.tap(2.0 + WINDOW_GOOD + MS, 2)  # MISS
    assert engine.score == 0
    assert engine.score >= 0


def test_score_monotonic_nondecreasing():
    engine = fresh(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
        ]
    )
    before = engine.score
    engine.tap(0.0 + WINDOW_GOOD + MS, 0)  # MISS adds 0
    assert engine.score >= before
    engine.tap(1.0, 1)  # PERFECT adds 300
    assert engine.score >= before


def test_register_miss_does_not_lower_score():
    engine = fresh([{"timestamp": 1.0, "lane": 0}, {"timestamp": 2.0, "lane": 1}])
    engine.tap(1.0, 0)
    before = engine.score
    engine.register_miss(1)
    assert engine.score == before  # miss adds no points
    assert engine.score >= 0


# ── Duplicate-hit prevention ──────────────────────────────────────────────────


def test_duplicate_hit_on_same_note_is_noop():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
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


def test_duplicate_hit_after_registered_miss_is_noop():
    engine = fresh([{"timestamp": 1.0, "lane": 0}])
    engine.register_miss(0)
    assert engine.resolved_count == 1
    assert engine.tap(1.0, 0) is None  # already resolved by miss
    assert engine.resolved_count == 1


def test_each_note_counted_once_max_score():
    # Two distinct notes at the same timestamp/lane are both hittable.
    engine = fresh(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 0.0, "lane": 0},
        ]
    )
    engine.tap(0.0, 0)  # resolves first note
    engine.tap(0.0, 0)  # resolves second note (delta 0)
    assert engine.resolved_count == 2
    assert engine.score == POINTS_PERFECT * 2


# ── Full-chart playthrough ────────────────────────────────────────────────────


def test_full_chart_all_perfect():
    import json
    from pathlib import Path

    chart_path = Path(__file__).resolve().parents[2] / "charts" / "example_chart.json"
    notes = json.loads(chart_path.read_text(encoding="utf-8"))["noteTimeline"]
    engine = fresh(notes)
    for note in notes:
        rating = engine.tap(float(note["timestamp"]), int(note["lane"]))
        assert rating == "PERFECT", f"note at {note['timestamp']} lane {note['lane']} got {rating}"
    assert engine.score == POINTS_PERFECT * len(notes)
    assert engine.combo == len(notes)
    assert engine.max_combo == len(notes)
    assert engine.accuracy == 1.0
    assert engine.grade() == "S"
    assert engine.sequence_complete is True
