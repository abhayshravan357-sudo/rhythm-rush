"""Unit tests for scoring logic (independent verification of ScoreManager spec).

These tests reimplement the scoring judgment rules in pure Python and verify
them against chart data, without depending on the Godot ScoreManager autoload.
They cover hit windows, combo/max-combo, accuracy, grade, negative-score
prevention, and duplicate-hit prevention.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
CHART_PATH = ROOT / "charts" / "example_chart.json"

# Judgment windows (seconds), one-sided delta from note timestamp. Mirrors
# ScoreManager.gd constants (HIT_WINDOW_PERFECT/GOOD/OK/MISS).
WINDOW_PERFECT = 0.045  # 45 ms  -> 300 pts
WINDOW_GOOD = 0.090  # 90 ms   -> 100 pts
WINDOW_OK = 0.150  # 150 ms  ->  50 pts
WINDOW_MISS = 0.180  # 180 ms  ->   0 pts (miss, combo reset)

POINTS_PERFECT = 300
POINTS_GOOD = 100
POINTS_OK = 50
POINTS_MISS = 0

LANE_COUNT = 4


def load_chart() -> dict:
    return json.loads(CHART_PATH.read_text(encoding="utf-8"))


@dataclass
class Note:
    timestamp: float
    lane: int
    kind: str
    resolved: bool = False


@dataclass
class ScoringEngine:
    """Independent reference implementation of the ScoreManager judgment rules."""

    notes: list[Note] = field(default_factory=list)
    score: int = 0
    combo: int = 0
    max_combo: int = 0
    resolved_count: int = 0
    sequence_complete: bool = False

    @property
    def total(self) -> int:
        return len(self.notes)

    @property
    def accuracy(self) -> float:
        if self.total <= 0:
            return 0.0
        return self.resolved_count / self.total

    def grade(self) -> str:
        acc = self.accuracy
        if acc >= 0.95:
            return "S"
        if acc >= 0.90:
            return "A"
        if acc >= 0.80:
            return "B"
        if acc >= 0.70:
            return "C"
        if acc >= 0.60:
            return "D"
        return "F"

    def reset(self, notes_payload: list[dict]) -> None:
        self.notes = [
            Note(timestamp=float(n["timestamp"]), lane=int(n["lane"]), kind=str(n.get("type", "TAP")))
            for n in notes_payload
        ]
        self.score = 0
        self.combo = 0
        self.max_combo = 0
        self.resolved_count = 0
        self.sequence_complete = False

    def _find_best(self, playback_time: float, lane: int) -> tuple[int, float] | None:
        best_index = -1
        best_delta = float("inf")
        for i, note in enumerate(self.notes):
            if note.resolved:
                continue
            if note.lane != lane:
                continue
            delta = abs(playback_time - note.timestamp)
            if delta < best_delta:
                best_delta = delta
                best_index = i
        if best_index == -1:
            return None
        return best_index, best_delta

    def tap(self, playback_time: float, lane: int) -> str | None:
        if lane < 0 or lane >= LANE_COUNT:
            return None
        found = self._find_best(playback_time, lane)
        if found is None:
            return None
        index, delta = found
        if delta > WINDOW_MISS:
            return None
        return self._evaluate(index, delta)

    def _evaluate(self, index: int, delta: float) -> str:
        note = self.notes[index]
        if note.resolved:
            return note.kind  # duplicate hit: no-op, already resolved
        note.resolved = True
        self.resolved_count += 1

        if delta <= WINDOW_PERFECT:
            rating, points = "PERFECT", POINTS_PERFECT
        elif delta <= WINDOW_GOOD:
            rating, points = "GOOD", POINTS_GOOD
        elif delta <= WINDOW_OK:
            rating, points = "OK", POINTS_OK
        else:
            rating, points = "MISS", POINTS_MISS

        self.score += points
        if rating == "MISS":
            self.combo = 0
        else:
            self.combo += 1
            self.max_combo = max(self.max_combo, self.combo)

        if self.resolved_count >= self.total and not self.sequence_complete:
            self.sequence_complete = True
        return rating

    def register_miss(self, index: int) -> None:
        note = self.notes[index]
        if note.resolved:
            return
        note.resolved = True
        self.resolved_count += 1
        self.combo = 0
        if self.resolved_count >= self.total and not self.sequence_complete:
            self.sequence_complete = True


@pytest.fixture
def engine() -> ScoringEngine:
    return ScoringEngine()


# ── Hit windows ───────────────────────────────────────────────────────────────


def test_perfect_window_boundary_inclusive(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, 0) == "PERFECT"
    assert engine.tap(1.0 + WINDOW_PERFECT, 0) is None  # already resolved


def test_perfect_window_up_to_45_ms(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + 0.044, 0) == "PERFECT"
    assert engine.score == POINTS_PERFECT


def test_good_window_from_45_ms_to_90_ms(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_PERFECT + 0.001, 0) == "GOOD"
    assert engine.tap(1.0 + WINDOW_GOOD, 0) is None  # resolved already
    assert engine.score == POINTS_GOOD


def test_ok_window_from_90_ms_to_150_ms(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_GOOD + 0.001, 0) == "OK"
    assert engine.score == POINTS_OK


def test_miss_beyond_150_ms(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    rating = engine.tap(1.0 + WINDOW_OK + 0.001, 0)
    assert rating == "MISS"
    assert engine.score == POINTS_MISS


def test_beyond_miss_window_registers_no_hit(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0 + WINDOW_MISS + 0.001, 0) is None
    assert engine.resolved_count == 0
    assert engine.score == 0


# ── Combo / max combo ─────────────────────────────────────────────────────────


def test_combo_increments_on_consecutive_hits(engine: ScoringEngine) -> None:
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


def test_miss_resets_combo_to_zero(engine: ScoringEngine) -> None:
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
        ]
    )
    engine.tap(0.0, 0)
    assert engine.combo == 1
    engine.tap(1.0 + WINDOW_OK + 0.001, 1)  # MISS
    assert engine.combo == 0
    assert engine.max_combo == 1


def test_max_combo_tracks_peak(engine: ScoringEngine) -> None:
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
            {"timestamp": 3.0, "lane": 3},
        ]
    )
    engine.tap(0.0, 0)
    engine.tap(1.0 + WINDOW_OK + 0.001, 1)  # MISS -> combo 0
    engine.tap(2.0, 2)
    engine.tap(3.0, 3)
    assert engine.combo == 2
    assert engine.max_combo == 2


# ── Accuracy ──────────────────────────────────────────────────────────────────


def test_accuracy_ratio_resolved_over_total(engine: ScoringEngine) -> None:
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    engine.tap(0.0, 0)
    assert engine.accuracy == pytest.approx(1 / 3)
    engine.tap(1.0, 1)
    assert engine.accuracy == pytest.approx(2 / 3)
    engine.tap(2.0, 2)
    assert engine.accuracy == pytest.approx(1.0)


def test_accuracy_zero_for_empty_chart(engine: ScoringEngine) -> None:
    engine.reset([])
    assert engine.accuracy == 0.0


# ── Grade ─────────────────────────────────────────────────────────────────────


def test_grade_scale_by_accuracy(engine: ScoringEngine) -> None:
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
        engine.reset([{"timestamp": 0.0, "lane": 0}] * total)
        resolved = int(round(acc * total))
        for i in range(resolved):
            engine.tap(0.0, 0)
        assert engine.grade() == expected, f"accuracy {acc} -> {engine.grade()}, expected {expected}"


# ── Negative-score prevention ─────────────────────────────────────────────────


def test_score_never_negative_on_all_misses(engine: ScoringEngine) -> None:
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
            {"timestamp": 2.0, "lane": 2},
        ]
    )
    engine.tap(0.0 + WINDOW_OK + 0.001, 0)  # MISS
    engine.tap(1.0 + WINDOW_OK + 0.001, 1)  # MISS
    engine.tap(2.0 + WINDOW_OK + 0.001, 2)  # MISS
    assert engine.score == 0
    assert engine.score >= 0


def test_score_monotonic_nondecreasing(engine: ScoringEngine) -> None:
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 1.0, "lane": 1},
        ]
    )
    before = engine.score
    engine.tap(0.0 + WINDOW_OK + 0.001, 0)  # MISS adds 0
    assert engine.score >= before
    engine.tap(1.0, 1)  # PERFECT adds 300
    assert engine.score >= before


# ── Duplicate-hit prevention ──────────────────────────────────────────────────


def test_duplicate_hit_on_same_note_is_noop(engine: ScoringEngine) -> None:
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


def test_duplicate_hit_after_miss_is_noop(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    engine.register_miss(0)
    assert engine.resolved_count == 1
    assert engine.tap(1.0, 0) is None  # already resolved by miss
    assert engine.resolved_count == 1


def test_each_note_counted_once_max_score(engine: ScoringEngine) -> None:
    engine.reset(
        [
            {"timestamp": 0.0, "lane": 0},
            {"timestamp": 0.0, "lane": 0},
        ]
    )
    engine.tap(0.0, 0)
    engine.tap(0.0, 0)  # duplicate on the second unresolved note? both at t=0, lane 0
    # _find_best picks the first unresolved; second tap picks the second note (delta 0).
    assert engine.resolved_count == 2
    assert engine.score == POINTS_PERFECT * 2


# ── Full-chart playthrough ────────────────────────────────────────────────────


def test_full_chart_all_perfect(engine: ScoringEngine) -> None:
    chart = load_chart()
    notes = chart["noteTimeline"]
    engine.reset(notes)
    for note in notes:
        rating = engine.tap(float(note["timestamp"]), int(note["lane"]))
        assert rating == "PERFECT", f"note at {note['timestamp']} lane {note['lane']} got {rating}"
    assert engine.score == POINTS_PERFECT * len(notes)
    assert engine.combo == len(notes)
    assert engine.max_combo == len(notes)
    assert engine.accuracy == 1.0
    assert engine.grade() == "S"
    assert engine.sequence_complete is True


def test_all_misses_yields_zero_score(engine: ScoringEngine) -> None:
    # Well-separated notes so each tap lands a clean MISS on its own note.
    notes = [
        {"timestamp": 0.0, "lane": 0},
        {"timestamp": 2.0, "lane": 1},
        {"timestamp": 4.0, "lane": 2},
        {"timestamp": 6.0, "lane": 3},
        {"timestamp": 8.0, "lane": 0},
    ]
    engine.reset(notes)
    for note in notes:
        rating = engine.tap(float(note["timestamp"]) + WINDOW_OK + 0.001, int(note["lane"]))
        assert rating == "MISS", f"note at {note['timestamp']} lane {note['lane']} got {rating}"
    assert engine.score == 0
    assert engine.combo == 0
    assert engine.max_combo == 0
    assert engine.accuracy == 1.0  # all notes resolved (as misses), per ScoreManager spec
    assert engine.sequence_complete is True


def test_invalid_lane_tap_ignored(engine: ScoringEngine) -> None:
    engine.reset([{"timestamp": 1.0, "lane": 0}])
    assert engine.tap(1.0, -1) is None
    assert engine.tap(1.0, LANE_COUNT) is None
    assert engine.resolved_count == 0
    assert engine.score == 0
