"""Pure-Python reference implementation of ScoreManager judgment rules.

Mirrors godot_project/scripts/ScoreManager.gd (hit precision evaluation,
combo/score tracking, accuracy, grade) so the scoring behavior can be verified
without the Godot engine. Windows are the MVP-01 calibrated targets:

    PERFECT : delta <= 50 ms   -> 300 pts, combo +1
    GOOD    : delta <= 100 ms  -> 100 pts, combo +1
    MISS    : delta > 100 ms   ->   0 pts, combo reset, note resolved

NOTE: godot_project/scripts/ScoreManager.gd currently ships the pre-calibration
windows (<=45 ms / <=90 ms / <=150 ms OK tier, plus a 180 ms outer miss bound).
This engine implements the calibrated MVP-01 targets (3 tiers, no OK tier).
The ScoreManager.gd update is tracked for Agent 00 coordination and must not be
applied here (ownership is outside tests/).
"""

from __future__ import annotations

from dataclasses import dataclass, field

# Calibrated judgment windows (seconds), one-sided delta from note timestamp.
WINDOW_PERFECT = 0.050  # 50 ms  -> 300 pts
WINDOW_GOOD = 0.100  # 100 ms -> 100 pts

POINTS_PERFECT = 300
POINTS_GOOD = 100
POINTS_MISS = 0

LANE_COUNT = 6  # matches charts/example_chart.json in this worktree (lanes 0-5)


@dataclass
class Note:
    timestamp: float
    lane: int
    kind: str
    resolved: bool = False


@dataclass
class ScoringEngine:
    """Reference implementation of the calibrated ScoreManager judgment rules."""

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
            Note(
                timestamp=float(n["timestamp"]),
                lane=int(n["lane"]),
                kind=str(n.get("type", "TAP")),
            )
            for n in notes_payload
        ]
        self.score = 0
        self.combo = 0
        self.max_combo = 0
        self.resolved_count = 0
        self.sequence_complete = False

    def _find_best(self, playback_time: float, lane: int):
        """Return (index, delta) of the closest unresolved note in lane, else None."""
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
        """Register a tap on lane at playback_time. Returns rating or None."""
        if lane < 0 or lane >= LANE_COUNT:
            return None
        found = self._find_best(playback_time, lane)
        if found is None:
            return None  # no unresolved note in lane (duplicate / nothing to hit)
        index, delta = found
        return self._evaluate(index, delta)

    def _evaluate(self, index: int, delta: float) -> str:
        note = self.notes[index]
        if note.resolved:
            return note.kind  # defensive: duplicate hit is a no-op
        note.resolved = True
        self.resolved_count += 1

        if delta <= WINDOW_PERFECT:
            rating, points = "PERFECT", POINTS_PERFECT
        elif delta <= WINDOW_GOOD:
            rating, points = "GOOD", POINTS_GOOD
        else:
            rating, points = "MISS", POINTS_MISS

        self.score += points
        if rating == "MISS":
            self.combo = 0
        else:
            self.combo += 1
            if self.combo > self.max_combo:
                self.max_combo = self.combo

        if self.resolved_count >= self.total and not self.sequence_complete:
            self.sequence_complete = True
        return rating

    def register_miss(self, index: int) -> None:
        """Resolve a specific note as a miss (combo reset, no points)."""
        note = self.notes[index]
        if note.resolved:
            return
        note.resolved = True
        self.resolved_count += 1
        self.combo = 0
        if self.resolved_count >= self.total and not self.sequence_complete:
            self.sequence_complete = True
