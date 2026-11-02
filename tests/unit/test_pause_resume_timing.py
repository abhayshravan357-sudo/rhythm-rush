"""Unit tests for MVP-03 pause/resume timing and input gating.

Covers: timing freeze during pause, no backward jump on resume,
input disabled during pause, GameStateManager integration.
"""

from __future__ import annotations

import pytest

from tests.unit.audio_sync import AudioSync
from tests.unit.game_controller import GameController, GameState
from tests.unit.lane_manager import LaneManager


# ── Pause/resume timing ─────────────────────────────────────────────────────


def test_pause_freezes_audio_clock():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    at_pause = sync.adjusted_system_time
    sync.pause_audio_pipeline()
    # Even with a large time jump, clock stays frozen.
    sync.process_tick(at_pause + 100.0)
    assert sync.adjusted_system_time == pytest.approx(at_pause)


def test_resume_has_no_backward_time_jump():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    at_pause = sync.adjusted_system_time
    sync.pause_audio_pipeline()
    sync.start_audio_pipeline()  # resume
    assert sync.adjusted_system_time == pytest.approx(at_pause)


def test_pause_then_resume_then_advance():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    at_pause = sync.adjusted_system_time
    sync.pause_audio_pipeline()
    sync.start_audio_pipeline()
    sync.process_tick(8.0)
    assert sync.adjusted_system_time == pytest.approx(at_pause + 3.0)


# ── Input gating during pause ───────────────────────────────────────────────


def test_lane_input_disabled_when_paused():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.pause_song()
    assert gc.state_manager.is_paused() is True

    lm = LaneManager()
    lm.set_input_enabled(gc.state_manager.is_playing())
    assert lm.is_input_enabled() is False
    assert lm.process_touch(100.0, pressed=True) is None


def test_lane_input_enabled_when_playing():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    assert gc.state_manager.is_playing() is True

    lm = LaneManager()
    lm.set_input_enabled(gc.state_manager.is_playing())
    assert lm.is_input_enabled() is True
    assert lm.process_touch(100.0, pressed=True) == 0


def test_resume_restores_playing_state_and_input():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.pause_song()
    assert gc.state_manager.current_state == GameState.PAUSED
    gc.resume_song()
    assert gc.state_manager.current_state == GameState.PLAYING
    assert gc.state_manager.is_playing() is True

    lm = LaneManager()
    lm.set_input_enabled(gc.state_manager.is_playing())
    assert lm.process_touch(100.0, pressed=True) == 0
