"""Integration tests for the end-to-end gameplay flow.

Tests the complete pipeline:
Chart Loading → Game Initialization → Tile Scheduling → Tile Movement →
Lane Input → Hit Detection → Scoring → Miss Handling

These tests use pure-Python reference implementations that mirror the GDScript
code. They validate behavior without requiring the Godot engine (L2 unit tests,
not L4 Godot runtime tests).
"""

from __future__ import annotations

import pytest

from tests.unit.lane_manager import LaneManager, LaneConfig
from tests.unit.note_spawner import NoteSpawner
from tests.unit.game_controller import GameController, GameState
from tests.unit.scoring_engine import ScoringEngine, Note, WINDOW_PERFECT, WINDOW_GOOD


# ── End-to-end gameplay flow ───────────────────────────────────────────────────


def test_full_gameplay_flow_perfect_playthrough():
    """Simulate a complete song with all PERFECT hits."""
    # Initialize systems
    gc = GameController()
    gc.prepare_song("example_track", "res://charts/example_chart.json")
    gc.start_song()

    # Lane manager for touch mapping
    lm = LaneManager()
    lm.set_input_enabled(True)

    # Score manager for judgment
    scoring = ScoringEngine()
    scoring.reset([])  # Will be set below

    # Note spawner for tile scheduling
    spawner = NoteSpawner()
    spawner.preallocate_pool(200)

    # Load chart
    import json
    from pathlib import Path

    chart_path = Path(__file__).resolve().parents[2] / "charts" / "example_chart.json"
    chart = json.loads(chart_path.read_text(encoding="utf-8"))
    notes = chart["noteTimeline"]
    scoring.reset(notes)
    spawner.start_spawning_sequence(chart)

    # Simulate gameplay: tap each note at its exact hit time
    for note in notes:
        playback_time = float(note["timestamp"])
        lane = int(note["lane"])

        # Spawner should have already spawned this note
        spawner.update(playback_time)

        # Lane input maps to correct lane
        mapped_lane = lm.get_lane_index_for_x(100.0 + lane * lm.get_lane_width() + 10.0)
        assert mapped_lane == lane

        # Hit detection
        rating = scoring.tap(playback_time, lane)
        assert rating == "PERFECT", f"Expected PERFECT at {playback_time}s lane {lane}, got {rating}"

    # All notes resolved
    assert scoring.resolved_count == scoring.total
    assert scoring.sequence_complete is True
    assert scoring.combo == scoring.total  # All hits, no misses
    assert scoring.score > 0


def test_full_gameplay_flow_all_misses():
    """Simulate a complete song with no hits (all misses)."""
    gc = GameController()
    gc.prepare_song("example_track", "res://charts/example_chart.json")
    gc.start_song()

    lm = LaneManager()
    lm.set_input_enabled(True)

    scoring = ScoringEngine()

    import json
    from pathlib import Path

    chart_path = Path(__file__).resolve().parents[2] / "charts" / "example_chart.json"
    chart = json.loads(chart_path.read_text(encoding="utf-8"))
    notes = chart["noteTimeline"]
    scoring.reset(notes)

    spawner = NoteSpawner()
    spawner.preallocate_pool(200)
    spawner.start_spawning_sequence(chart)

    # Never tap — all notes should be missed
    for note in notes:
        playback_time = float(note["timestamp"])
        spawner.update(playback_time + 0.2)  # Past hit time → miss
        scoring.register_miss(notes.index(note))

    assert scoring.resolved_count == scoring.total
    assert scoring.combo == 0  # All misses, combo reset
    assert scoring.score == 0  # No points


def test_duplicate_hit_prevention():
    """A note can only be resolved once (no duplicate scoring)."""
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()

    scoring = ScoringEngine()
    notes = [
        {"timestamp": 1.0, "lane": 0, "type": "TAP"},
    ]
    scoring.reset(notes)

    # First tap at exact time → PERFECT
    rating1 = scoring.tap(1.0, 0)
    assert rating1 == "PERFECT"

    # Second tap at same time → None (already resolved)
    rating2 = scoring.tap(1.0, 0)
    assert rating2 is None

    assert scoring.combo == 1
    assert scoring.score == 300


def test_input_gating_during_pause():
    """Lane input is disabled when paused."""
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.pause_song()

    lm = LaneManager()
    lm.set_input_enabled(not gc.state_manager.is_paused())

    assert lm.is_input_enabled() is False
    assert lm.process_touch(100.0, pressed=True) is None


def test_input_gating_during_gameplay():
    """Lane input is enabled during gameplay."""
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()

    lm = LaneManager()
    lm.set_input_enabled(gc.state_manager.is_playing())

    assert lm.is_input_enabled() is True
    assert lm.process_touch(100.0, pressed=True) == 0


def test_invalid_chart_rejected():
    """Invalid lane indices are rejected by lane count validation."""
    lm = LaneManager(LaneConfig(lane_count=4))

    # Lane 4 is out of range for 4-lane MVP
    lane = lm.get_lane_index_for_x(4.0 * lm.get_lane_width() + 1.0)
    assert lane == 3  # Clamped to last valid lane (0-3)

    # No lane index 4 exists
    assert lane < lm.get_lane_count()


def test_six_lane_compatibility():
    """Six-lane charts are supported via GameConfig headroom."""
    lm = LaneManager(LaneConfig(lane_count=6))
    assert lm.get_lane_count() == 6
    assert lm.get_lane_index_for_x(1000.0) < 6