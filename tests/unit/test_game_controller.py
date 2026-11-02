"""Unit tests for GameController reference implementation (game_controller.py).

Tests initialization, state transitions, failure handling, pause/resume,
and game lifecycle. Mirrors godot_project/scripts/core/GameController.gd.
"""

from __future__ import annotations

import pytest

from tests.unit.game_controller import (
    GameController,
    GameStateManager,
    GameState,
    ScoreManager,
    AudioSync,
)


# ── GameController lifecycle ───────────────────────────────────────────────────


def test_prepare_song_transitions_to_loading():
    gc = GameController()
    result = gc.prepare_song("song1", "res://charts/song1.json")
    assert result is True
    assert gc.state_manager.is_paused() is False
    assert gc.state_manager.current_state == GameState.LOADING
    assert gc.song_loaded_called is True


def test_start_song_transitions_to_playing():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    assert gc.is_game_active is True
    assert gc.state_manager.current_state == GameState.PLAYING
    assert gc.audio_sync.active is True


def test_pause_song_transitions_to_paused():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.pause_song()
    assert gc.state_manager.current_state == GameState.PAUSED


def test_resume_song_transitions_back_to_playing():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.pause_song()
    gc.resume_song()
    assert gc.state_manager.current_state == GameState.PLAYING


def test_complete_song_transitions_to_results():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.complete_song()
    assert gc.is_game_active is False
    assert gc.state_manager.current_state == GameState.RESULTS
    assert gc.audio_sync.active is False


def test_exit_to_menu_returns_to_main_menu():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    gc.exit_to_menu()
    assert gc.state_manager.current_state == GameState.MAIN_MENU
    assert gc.is_game_active is False
    assert gc.current_chart_path == ""
    assert gc.current_song_id == ""


# ── GameStateManager ───────────────────────────────────────────────────────────


def test_state_transitions_prevent_duplicates():
    gsm = GameStateManager()
    gsm.transition_to(GameState.PLAYING)
    gsm.transition_to(GameState.PLAYING)  # No-op, same state
    assert gsm.current_state == GameState.PLAYING
    assert gsm.previous_state == GameState.MAIN_MENU


def test_is_playing_returns_true_only_during_playing():
    gsm = GameStateManager()
    assert gsm.is_playing() is False
    gsm.transition_to(GameState.PLAYING)
    assert gsm.is_playing() is True
    gsm.transition_to(GameState.PAUSED)
    assert gsm.is_playing() is False


def test_reset_to_main_menu():
    gsm = GameStateManager()
    gsm.transition_to(GameState.RESULTS)
    gsm.reset_to_main_menu()
    assert gsm.current_state == GameState.MAIN_MENU


# ── ScoreManager integration ───────────────────────────────────────────────────


def test_score_manager_reset_scoring_matrix():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    assert gc.score_manager.chart_loaded is True


# ── AudioSync integration ──────────────────────────────────────────────────────


def test_audio_sync_starts_on_song_start():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    assert gc.audio_sync.active is False
    gc.start_song()
    assert gc.audio_sync.active is True
    gc.complete_song()
    assert gc.audio_sync.active is False