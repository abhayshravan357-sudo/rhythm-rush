"""Integration tests for MVP-03 song completion.

Covers: song completion detection, sequence_tracking_concluded,
consistent final statistics, and end-to-end playthrough to completion.
"""

from __future__ import annotations

import pytest

from tests.unit.audio_sync import AudioSync
from tests.unit.game_controller import GameController, GameState
from tests.unit.lane_manager import LaneManager
from tests.unit.mvp03_scoring import ScoringEngine


# ── Song completion detection ───────────────────────────────────────────────


def test_audio_sync_song_completion_at_duration():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.set_song_duration(10.0)
    sync.start_audio_pipeline()
    sync.process_tick(9.99)
    assert sync.song_completed is False
    sync.process_tick(10.0)
    assert sync.song_completed is True


def test_game_controller_complete_song_transitions_to_results():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    assert gc.state_manager.current_state == GameState.PLAYING
    gc.complete_song()
    assert gc.state_manager.current_state == GameState.RESULTS
    assert gc.is_game_active is False


# ── End-to-end playthrough to completion ────────────────────────────────────


def test_full_playthrough_all_perfect_to_completion():
    """Simulate a complete song: all PERFECT hits, sequence completes."""
    engine = ScoringEngine()
    notes = [
        {"timestamp": 0.0, "lane": 0, "type": "TAP"},
        {"timestamp": 1.0, "lane": 1, "type": "TAP"},
        {"timestamp": 2.0, "lane": 2, "type": "TAP"},
        {"timestamp": 3.0, "lane": 3, "type": "TAP"},
        {"timestamp": 4.0, "lane": 0, "type": "TAP"},
    ]
    engine.reset(notes)
    lane_manager = LaneManager()
    lane_manager.set_input_enabled(True)

    for note in notes:
        t = float(note["timestamp"])
        lane = int(note["lane"])
        mapped = lane_manager.get_lane_index_for_x(100.0 + lane * lane_manager.get_lane_width() + 10.0)
        assert mapped == lane
        rating = engine.tap(t, lane)
        assert rating == "PERFECT", f"note at {t}s lane {lane} got {rating}"

    assert engine.resolved_count == engine.total
    assert engine.sequence_complete is True
    assert engine.combo == 5
    assert engine.max_combo == 5
    assert engine.score == 5 * 300
    assert engine.accuracy == pytest.approx(100.0)
    assert engine.grade() == "S"


def test_full_playthrough_with_misses_to_completion():
    """Simulate a complete song: mix of hits and misses, sequence completes."""
    engine = ScoringEngine()
    notes = [
        {"timestamp": 0.0, "lane": 0, "type": "TAP"},
        {"timestamp": 1.0, "lane": 1, "type": "TAP"},
        {"timestamp": 2.0, "lane": 2, "type": "TAP"},
    ]
    engine.reset(notes)
    # Hit first two perfectly, miss the third
    engine.tap(0.0, 0)
    engine.tap(1.0, 1)
    engine.register_miss(2)

    assert engine.resolved_count == engine.total
    assert engine.sequence_complete is True
    assert engine.combo == 0  # miss resets combo
    assert engine.max_combo == 2
    assert engine.score == 600  # 2 * 300
    assert engine.miss_count == 1
