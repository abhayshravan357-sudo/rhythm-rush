"""Unit tests for pause/resume synchronization and input timing gating.

Verifies GameController state transitions around pause/resume and that audio
stays active while paused but stops on completion/game over.
"""

from __future__ import annotations

from tests.unit.game_controller import GameController, GameState


def test_pause_then_resume_returns_to_playing():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    assert gc.state_manager.current_state == GameState.PLAYING
    assert gc.audio_sync.active is True
    gc.pause_song()
    assert gc.state_manager.current_state == GameState.PAUSED
    gc.resume_song()
    assert gc.state_manager.current_state == GameState.PLAYING


def test_resume_from_non_paused_is_noop():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.resume_song()  # not paused -> no-op
    assert gc.state_manager.current_state == GameState.PLAYING


def test_audio_active_during_playing_and_paused():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    assert gc.audio_sync.active is True
    gc.pause_song()
    assert gc.state_manager.current_state == GameState.PAUSED
    assert gc.audio_sync.active is True  # pause does not stop audio


def test_complete_song_stops_audio_and_enters_results():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.complete_song()
    assert gc.is_game_active is False
    assert gc.state_manager.current_state == GameState.RESULTS
    assert gc.audio_sync.active is False


def test_game_over_stops_audio():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.game_over()
    assert gc.audio_sync.active is False
    assert gc.state_manager.current_state == GameState.GAME_OVER
