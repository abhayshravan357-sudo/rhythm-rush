"""Pure-Python reference implementation of NoteSpawner scheduling and pooling.

Mirrors godot_project/scripts/NoteSpawner.gd (chart-driven scheduling, audio-clock
spawning, object pooling, tile retirement) so spawning behavior can be verified
without the Godot engine.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class NoteSpec:
    timestamp: float
    lane: int
    note_type: str = "TAP"
    duration: float = 0.0


@dataclass
class DeployedTile:
    timeline_index: int
    lane_index: int
    note_type: str
    is_active: bool = True


class NoteSpawner:
    """Reference implementation of NoteSpawner chart-driven scheduling and pooling."""

    APPROACH_TIME: float = 1.5  # seconds before hit time when tile becomes visible
    MAX_POOL_LIMIT: int = 200

    def __init__(self):
        self.preallocated_pool: list[DeployedTile] = []
        self.active_tiles: list[DeployedTile] = []
        self._next_note_index: int = 0
        self._tracking_timeline: list[NoteSpec] = []
        self._pool_exhaustion_warnings: int = 0

    def start_spawning_sequence(self, chart_data: dict) -> None:
        """Initialize spawning from a chart payload."""
        timeline_raw = chart_data.get("noteTimeline", [])
        self._tracking_timeline = [
            NoteSpec(
                timestamp=float(n.get("timestamp", 0.0)),
                lane=int(n.get("lane", 0)),
                note_type=str(n.get("type", "TAP")),
                duration=float(n.get("duration", 0.0)),
            )
            for n in timeline_raw
        ]
        self._tracking_timeline.sort(key=lambda n: n.timestamp)
        self._next_note_index = 0
        self.active_tiles.clear()
        for tile in self.preallocated_pool:
            tile.is_active = False

    def preallocate_pool(self, count: int | None = None) -> None:
        """Pre-allocate pool elements (no runtime instantiation during gameplay)."""
        limit = count if count is not None else self.MAX_POOL_LIMIT
        self.preallocated_pool = [
            DeployedTile(timeline_index=-1, lane_index=-1, note_type="TAP", is_active=False)
            for _ in range(limit)
        ]

    def update(self, playback_time: float) -> None:
        """Spawn notes entering the approach window; synchronize active tiles."""
        self._spawn_due_notes(playback_time)
        self._retire_expired_tiles(playback_time)

    def _spawn_due_notes(self, playback_time: float) -> None:
        while self._next_note_index < len(self._tracking_timeline):
            note = self._tracking_timeline[self._next_note_index]
            hit_time = note.timestamp

            if playback_time >= hit_time:
                # Hit time passed without spawning — skip (resolved as miss elsewhere)
                self._next_note_index += 1
                continue

            if hit_time - self.APPROACH_TIME <= playback_time:
                self._deploy_note(note, self._next_note_index)
                self._next_note_index += 1
            else:
                break  # Sorted timeline; no later note qualifies yet

    def _deploy_note(self, note: NoteSpec, timeline_index: int) -> None:
        for tile in self.preallocated_pool:
            if not tile.is_active:
                tile.is_active = True
                tile.timeline_index = timeline_index
                tile.lane_index = note.lane
                tile.note_type = note.note_type
                self.active_tiles.append(tile)
                return
        self._pool_exhaustion_warnings += 1

    def _retire_expired_tiles(self, playback_time: float) -> None:
        """Retire tiles that have scrolled well past the judgment line."""
        # In the GDScript, this is based on Y position. Here we use a time-based
        # proxy: notes whose hit time is far enough in the past are retired.
        still_active: list[DeployedTile] = []
        for tile in self.active_tiles:
            if not tile.is_active:
                continue
            note = self._tracking_timeline[tile.timeline_index]
            # Retire when well past hit time (proxy for Y > judgment_y + 60)
            if playback_time > note.timestamp + 0.5:
                tile.is_active = False
            else:
                still_active.append(tile)
        self.active_tiles = still_active

    def get_active_count(self) -> int:
        return sum(1 for t in self.active_tiles if t.is_active)

    def get_pool_exhaustion_warnings(self) -> int:
        return self._pool_exhaustion_warnings

    def is_note_expired(self, timeline_index: int, playback_time: float) -> bool:
        """Check if a note's hit time has passed without being spawned."""
        if timeline_index < 0 or timeline_index >= len(self._tracking_timeline):
            return False
        note = self._tracking_timeline[timeline_index]
        return playback_time > note.timestamp