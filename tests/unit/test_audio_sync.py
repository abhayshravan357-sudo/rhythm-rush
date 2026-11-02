"""Unit tests for AudioSync hardware-clock time vs note timestamps.

Verifies the audio clock advances only while active, freezes while paused,
resumes after pause, and reports sync drift against note hit timestamps.
"""

from __future__ import annotations

import pytest

from tests.unit.audio_sync import AudioSync


def test_clock_starts_at_zero_when_active():
    sync = AudioSync()
    sync.start_audio_pipeline()
    assert sync.active is True
    assert sync.get_playback_time() == 0.0


def test_clock_advances_while_active():
    sync = AudioSync()
    sync.start_audio_pipeline()
    sync.advance(1.0)
    assert sync.get_playback_time() == pytest.approx(1.0)


def test_clock_does_not_advance_when_paused():
    sync = AudioSync()
    sync.start_audio_pipeline()
    sync.pause()
    sync.advance(2.0)
    assert sync.get_playback_time() == 0.0
    assert sync.is_paused() is True


def test_clock_resumes_after_pause():
    sync = AudioSync()
    sync.start_audio_pipeline()
    sync.advance(1.0)
    sync.pause()
    sync.advance(1.0)
    assert sync.get_playback_time() == pytest.approx(1.0)
    sync.resume()
    sync.advance(1.0)
    assert sync.get_playback_time() == pytest.approx(2.0)
    assert sync.is_paused() is False


def test_sync_drift_zero_at_exact_hit_time():
    sync = AudioSync()
    sync.start_audio_pipeline()
    sync.set_playback_time(1.0)
    assert sync.sync_drift_ms(1.0) == 0.0
    assert sync.within_hit_window(1.0, 50.0) is True


def test_sync_drift_exceeds_perfect_window():
    sync = AudioSync()
    sync.start_audio_pipeline()
    sync.set_playback_time(1.060)  # 60 ms late
    assert sync.sync_drift_ms(1.0) > 50.0
    assert sync.within_hit_window(1.0, 50.0) is False


def test_sync_drift_within_good_window():
    sync = AudioSync()
    sync.start_audio_pipeline()
    sync.set_playback_time(1.080)  # 80 ms late
    assert sync.within_hit_window(1.0, 100.0) is True


def test_audio_stops_on_stop_audio_pipeline():
    sync = AudioSync()
    sync.start_audio_pipeline()
    assert sync.active is True
    sync.stop_audio_pipeline()
    assert sync.active is False
