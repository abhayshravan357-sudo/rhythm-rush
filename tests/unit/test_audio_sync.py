"""Unit tests for the MVP-03 AudioSync reference implementation.

Covers: audio-clock calculation, offset calibration, pause/resume timing
without corruption, timing drift, and song completion detection.
"""

from __future__ import annotations

import pytest

from tests.unit.audio_sync import AudioSync


# ── Construction and defaults ───────────────────────────────────────────────


def test_defaults_are_zeroed():
    sync = AudioSync()
    assert sync.adjusted_system_time == 0.0
    assert sync.current_audio_time == 0.0
    assert sync.local_hardware_offset == 0.0
    assert sync.is_playing() is False
    assert sync.is_paused_state() is False


def test_approach_time_constant():
    assert AudioSync.APPROACH_TIME == 1.5


# ── Audio clock calculation ─────────────────────────────────────────────────


def test_adjusted_time_equals_raw_minus_offset():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(10.0)
    assert sync.get_raw_audio_time() == pytest.approx(10.0)
    assert sync.get_playback_position_seconds() == pytest.approx(10.0)


def test_offset_is_applied_to_adjusted_time():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.set_offset(0.250)  # 250 ms hardware offset
    sync.start_audio_pipeline()
    sync.process_tick(10.0)
    assert sync.adjusted_system_time == pytest.approx(9.750)


def test_get_offset_returns_configured_offset():
    sync = AudioSync()
    sync.set_offset(-0.050)
    assert sync.get_offset() == pytest.approx(-0.050)


# ── Pause / resume timing (no corruption) ───────────────────────────────────


def test_pause_freezes_adjusted_time():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    paused_at = sync.adjusted_system_time
    sync.pause_audio_pipeline()
    assert sync.is_paused_state() is True
    assert sync.is_playing() is False
    # Time must not advance while paused.
    sync.process_tick(999.0)
    assert sync.adjusted_system_time == pytest.approx(paused_at)


def test_resume_continues_from_paused_position_no_backward_jump():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    paused_at = sync.adjusted_system_time
    sync.pause_audio_pipeline()
    sync.start_audio_pipeline()  # resume from pause
    assert sync.is_paused_state() is False
    assert sync.is_playing() is True
    # adjusted_system_time continues from where it paused (no jump backward).
    assert sync.adjusted_system_time == pytest.approx(paused_at)


def test_resume_after_pause_advances_on_subsequent_tick():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    paused_at = sync.adjusted_system_time
    sync.pause_audio_pipeline()
    sync.start_audio_pipeline()  # resume
    sync.process_tick(8.0)
    assert sync.adjusted_system_time == pytest.approx(paused_at + 3.0)


def test_pause_when_not_playing_is_noop():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.pause_audio_pipeline()
    assert sync.is_paused_state() is False


def test_double_pause_is_noop():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    sync.pause_audio_pipeline()
    first_paused = sync._paused_adjusted_time
    sync.pause_audio_pipeline()  # second pause should be no-op
    assert sync._paused_adjusted_time == pytest.approx(first_paused)


# ── Drift analysis ──────────────────────────────────────────────────────────


def test_drift_ms_equals_offset_during_playback():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.set_offset(0.120)  # 120 ms offset
    sync.start_audio_pipeline()
    sync.process_tick(5.0)
    sync.process_tick(6.0)
    # drift = current_audio_time - adjusted_system_time = offset
    assert sync.drift_ms() == pytest.approx(120.0)


def test_drift_ms_zero_when_no_samples():
    sync = AudioSync()
    assert sync.drift_ms() == 0.0
    assert sync.drift_sample_count() == 0


# ── Song completion detection ───────────────────────────────────────────────


def test_song_completed_when_playback_reaches_duration():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    sync.set_song_duration(10.0)
    sync.start_audio_pipeline()
    sync.process_tick(9.0)
    assert sync.song_completed is False
    sync.process_tick(10.0)
    assert sync.song_completed is True
    assert sync.is_playing() is False


def test_no_completion_when_duration_unknown():
    sync = AudioSync()
    sync.initialize_playback_channel(None)
    # song_duration defaults to 0.0 (unknown) — should not auto-complete
    sync.start_audio_pipeline()
    sync.process_tick(999.0)
    assert sync.song_completed is False
