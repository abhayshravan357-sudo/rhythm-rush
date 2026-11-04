"""Unit tests for object pool behavior.

Tests that the NoteSpawner object pool pattern (pre-allocated nodes, no
runtime instantiation, safe reuse) works correctly. These are pure-Python
tests that mirror the GDScript NoteSpawner.gd logic.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class PoolTile:
    """Represents a pooled tile node."""
    is_active: bool = False
    timeline_index: int = -1
    lane_index: int = -1
    note_type: str = "TAP"


class NoteSpawnerPool:
    """Pure-Python reference implementation of NoteSpawner's object pool."""

    MAX_POOL_LIMIT: int = 200

    def __init__(self):
        self.preallocated_pool: list[PoolTile] = []
        self.active_tiles: list[PoolTile] = []
        self._next_note_index: int = 0
        self._tracking_timeline: list[dict] = []
        self._deployed_timeline_indices: set[int] = set()
        self._pool_exhaustion_warnings: int = 0

    def preallocate_pool(self, count: int | None = None) -> None:
        limit = count if count is not None else self.MAX_POOL_LIMIT
        self.preallocated_pool = [
            PoolTile() for _ in range(limit)
        ]

    def start_spawning_sequence(self, chart_data: list[dict]) -> None:
        self._tracking_timeline = sorted(chart_data, key=lambda n: n["timestamp"])
        self._next_note_index = 0
        self.active_tiles.clear()
        self._deployed_timeline_indices.clear()
        for tile in self.preallocated_pool:
            tile.is_active = False
            tile.timeline_index = -1
            tile.lane_index = -1

    def update(self, playback_time: float) -> None:
        self._spawn_due_notes(playback_time)
        self._retire_expired_tiles(playback_time)

    def _spawn_due_notes(self, playback_time: float) -> None:
        while self._next_note_index < len(self._tracking_timeline):
            note = self._tracking_timeline[self._next_note_index]
            hit_time = note["timestamp"]
            if playback_time >= hit_time:
                self._next_note_index += 1
                continue
            if hit_time - 1.5 <= playback_time:  # APPROACH_TIME = 1.5
                self._deploy_note(note, self._next_note_index)
                self._next_note_index += 1
            else:
                break

    def _deploy_note(self, note: dict, timeline_index: int) -> None:
        for tile in self.preallocated_pool:
            if not tile.is_active:
                tile.is_active = True
                tile.timeline_index = timeline_index
                tile.lane_index = note["lane"]
                tile.note_type = note["type"]
                self._deployed_timeline_indices.add(timeline_index)
                self.active_tiles.append(tile)
                return
        self._pool_exhaustion_warnings += 1

    def _retire_expired_tiles(self, playback_time: float) -> None:
        still_active = []
        for tile in self.active_tiles:
            if not tile.is_active:
                continue
            note = self._tracking_timeline[tile.timeline_index]
            if playback_time > note["timestamp"] + 0.5:
                tile.is_active = False
            else:
                still_active.append(tile)
        self.active_tiles = still_active

    def get_active_count(self) -> int:
        return sum(1 for t in self.active_tiles if t.is_active)

    def get_pool_exhaustion_warnings(self) -> int:
        return self._pool_exhaustion_warnings

    def get_pool_utilization(self) -> float:
        """Return fraction of pool currently active (0.0 to 1.0)."""
        return self.get_active_count() / len(self.preallocated_pool)


# ── Pool tests ──────────────────────────────────────────────────────────────


def test_preallocate_pool_creates_inactive_tiles():
    spawner = NoteSpawnerPool()
    spawner.preallocate_pool(10)
    assert len(spawner.preallocated_pool) == 10
    assert all(not t.is_active for t in spawner.preallocated_pool)


def test_default_pool_limit_is_200():
    spawner = NoteSpawnerPool()
    assert spawner.MAX_POOL_LIMIT == 200


def test_pool_does_not_grow_during_gameplay():
    """Object pool never instantiates new nodes during gameplay —
    only reuses pre-allocated ones."""
    spawner = NoteSpawnerPool()
    spawner.preallocate_pool(5)
    spawner.start_spawning_sequence([
        {"timestamp": 2.0, "lane": 0, "type": "TAP"},
        {"timestamp": 2.1, "lane": 1, "type": "TAP"},
        {"timestamp": 2.2, "lane": 2, "type": "TAP"},
        {"timestamp": 2.3, "lane": 3, "type": "TAP"},
        {"timestamp": 2.4, "lane": 0, "type": "TAP"},
        {"timestamp": 2.5, "lane": 1, "type": "TAP"},  # 6th note — pool exhausted
    ])
    spawner.update(1.0)  # All within approach window
    assert spawner.get_active_count() == 5  # Pool limit of 5
    assert spawner.get_pool_exhaustion_warnings() == 1  # 6th note couldn't spawn


def test_pool_reuse_after_retirement():
    """Pool elements are reused after tiles retire — no new allocations."""
    spawner = NoteSpawnerPool()
    spawner.preallocate_pool(2)
    spawner.start_spawning_sequence([
        {"timestamp": 2.0, "lane": 0, "type": "TAP"},
        {"timestamp": 2.1, "lane": 1, "type": "TAP"},
    ])
    spawner.update(1.0)
    assert spawner.get_active_count() == 2

    # Advance past hit time → both retire
    spawner.update(3.0)
    assert spawner.get_active_count() == 0

    # Spawn again → pool elements reused
    spawner.start_spawning_sequence([
        {"timestamp": 5.0, "lane": 2, "type": "TAP"},
    ])
    spawner.update(4.0)
    assert spawner.get_active_count() == 1


def test_pool_utilization_stays_under_one():
    """Pool utilization should never exceed 1.0 (100%)."""
    spawner = NoteSpawnerPool()
    spawner.preallocate_pool(3)
    spawner.start_spawning_sequence([
        {"timestamp": 2.0, "lane": 0, "type": "TAP"},
        {"timestamp": 2.1, "lane": 1, "type": "TAP"},
        {"timestamp": 2.2, "lane": 2, "type": "TAP"},
        {"timestamp": 2.3, "lane": 0, "type": "TAP"},  # 4th — pool exhausted
    ])
    spawner.update(1.0)
    assert spawner.get_pool_utilization() <= 1.0


def test_expired_notes_not_spawned():
    """Notes whose hit time has passed are never spawned as valid tiles."""
    spawner = NoteSpawnerPool()
    spawner.preallocate_pool(10)
    spawner.start_spawning_sequence([
        {"timestamp": 1.0, "lane": 0, "type": "TAP"},
    ])
    # Playback time is past the hit time — note should NOT spawn
    spawner.update(1.5)
    assert spawner.get_active_count() == 0
