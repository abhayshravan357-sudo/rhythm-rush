"""Pure-Python reference implementation of MVP-03 ScoreManager scoring.

Mirrors godot_project/scripts/ScoreManager.gd MVP-03 scoring refinement:
  - Judgment windows: PERFECT <= 50 ms (300 pts), GOOD <= 100 ms (100 pts), MISS > 100 ms (0 pts).
  - Combo-based score multiplier: tiers 1x/2x/3x/4x, capped at 4x.
  - Accuracy = judgment-based timing precision (perfect*300 + good*100) / (total * 300) * 100.
  - Each note resolved exactly once; duplicate hits are no-ops; score never negative.
"""

from __future__ import annotations

from dataclasses import dataclass, field

WINDOW_PERFECT = 0.050  # 50 ms
WINDOW_GOOD = 0.100  # 100 ms

POINTS_PERFECT = 300
POINTS_GOOD = 100
POINTS_MISS = 0

MAX_MULTIPLIER = 4
COMBO_TIER_STEP = 10

LANE_COUNT = 4


@dataclass
class Note:
    timestamp: float
    lane: int
    kind: str = "TAP"
    resolved: bool = False


@dataclass
class ScoringEngine:
    """Reference implementation of the MVP-03 calibrated ScoreManager rules."""

    notes: list[Note] = field(default_factory=list)
    score: int = 0
    combo: int = 0
    max_combo: int = 0
    resolved_count: int = 0
    sequence_complete: bool = False
    perfect_count: int = 0
    good_count: int = 0
    miss_count: int = 0

    @property
    def total(self) -> int:
        return len(self.notes)

    def get_multiplier(self) -> int:
        tier = 1 + (self.combo // COMBO_TIER_STEP)
        return max(1, min(tier, MAX_MULTIPLIER))

    @property
    def accuracy(self) -> float:
        if self.total <= 0:
            return 0.0
        earned = self.perfect_count * POINTS_PERFECT + self.good_count * POINTS_GOOD
        max_possible = self.total * POINTS_PERFECT
        acc = earned / max_possible * 100.0
        return max(0.0, min(acc, 100.0))

    def grade(self) -> str:
        acc = self.accuracy
        if acc >= 95.0:
            return "S"
        if acc >= 90.0:
            return "A"
        if acc >= 80.0:
            return "B"
        if acc >= 70.0:
            return "C"
        if acc >= 60.0:
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
        self.perfect_count = 0
        self.good_count = 0
        self.miss_count = 0

    def _find_best(self, playback_time: float, lane: int):
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

    def tap(self, playback_time: float, lane: int):
        if lane < 0 or lane >= LANE_COUNT:
            return None
        found = self._find_best(playback_time, lane)
        if found is None:
            return None
        index, delta = found
        return self._evaluate(index, delta)

    def _evaluate(self, index: int, delta: float) -> str:
        note = self.notes[index]
        if note.resolved:
            return note.kind  # duplicate hit: no-op
        note.resolved = True
        self.resolved_count += 1

        if delta <= WINDOW_PERFECT:
            rating, base_points = "PERFECT", POINTS_PERFECT
            self.perfect_count += 1
            self.combo += 1
        elif delta <= WINDOW_GOOD:
            rating, base_points = "GOOD", POINTS_GOOD
            self.good_count += 1
            self.combo += 1
        else:
            rating, base_points = "MISS", POINTS_MISS
            self.miss_count += 1
            self.combo = 0

        multiplier = self.get_multiplier()
        self.score += base_points * multiplier
        if self.combo > self.max_combo:
            self.max_combo = self.combo

        if self.resolved_count >= self.total and not self.sequence_complete:
            self.sequence_complete = True
        return rating

    def register_miss(self, index: int) -> None:
        note = self.notes[index]
        if note.resolved:
            return
        note.resolved = True
        self.resolved_count += 1
        self.miss_count += 1
        self.combo = 0
        if self.resolved_count >= self.total and not self.sequence_complete:
            self.sequence_complete = True
