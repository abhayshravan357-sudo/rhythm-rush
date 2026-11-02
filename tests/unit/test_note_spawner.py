"""Unit tests for NoteSpawner reference implementation (note_spawner.py).

Tests tile scheduling, note expiration, hit detection, duplicate prevention,
object-pool reuse, and pool exhaustion. Mirrors godot_project/scripts/NoteSpawner.gd.
"""

from __future__ import annotations

import pytest

from tests.unit.note_spawner import NoteSpawner, NoteSpec


# ── Pool preallocation ─────────────────────────────────────────────────────────


def test_preallocate_pool_creates_inactive_tiles():
    spawner = NoteSpawner()
    spawner.preallocate_pool(10)
    assert len(spawner.preallocated_pool) == 10
    assert all(not t.is_active for t in spawner.preallocated_pool)


def test_default_pool_limit_is_200():
    spawner = NoteSpawner()
    assert spawner.MAX_POOL_LIMIT == 200


# ── Chart-driven scheduling ────────────────────────────────────────────────────


def test_start_spawning_sequence_sorts_by_timestamp():
    spawner = NoteSpawner()
    spawner.preallocate_pool(50)
    chart = {
        "noteTimeline": [
            {"timestamp": 3.0, "lane": 2, "type": "TAP"},
            {"timestamp": 1.0, "lane": 0, "type": "TAP"},
            {"timestamp": 2.0, "lane": 1, "type": "HOLD", "duration": 0.5},
        ]
    }
    spawner.start_spawning_sequence(chart)
    timestamps = [n.timestamp for n in spawner._tracking_timeline]
    assert timestamps == [1.0, 2.0, 3.0]


def test_notes_spawn_when_within_approach_window():
    spawner = NoteSpawner()
    spawner.preallocate_pool(50)
    chart = {
        "noteTimeline": [
            {"timestamp": 2.0, "lane": 0, "type": "TAP"},
        ]
    }
    spawner.start_spawning_sequence(chart)

    # At playback_time = 0.5, note at 2.0 is within APPROACH_TIME (1.5s) → should spawn
    spawner.update(0.5)
    assert spawner.get_active_count() == 1


def test_notes_do_not_spawn_before_approach_window():
    spawner = NoteSpawner()
    spawner.preallocate_pool(50)
    chart = {
        "noteTimeline": [
            {"timestamp": 5.0, "lane": 0, "type": "TAP"},
        ]
    }
    spawner.start_spawning_sequence(chart)

    # At playback_time = 3.0, note at 5.0 is 2.0s away (> APPROACH_TIME=1.5s) → no spawn
    spawner.update(3.0)
    assert spawner.get_active_count() == 0


def test_notes_do_not_spawn_after_hit_time():
    spawner = NoteSpawner()
    spawner.preallocate_pool(50)
    chart = {
        "noteTimeline": [
            {"timestamp": 1.0, "lane": 0, "type": "TAP"},
        ]
    }
    spawner.start_spawning_sequence(chart)

    # At playback_time = 1.5, hit time (1.0) has passed → note should NOT spawn
    spawner.update(1.5)
    assert spawner.get_active_count() == 0


# ── Object pooling ─────────────────────────────────────────────────────────────


def test_pool_reuse_after_retirement():
    spawner = NoteSpawner()
    spawner.preallocate_pool(2)
    chart = {
        "noteTimeline": [
            {"timestamp": 2.0, "lane": 0, "type": "TAP"},
            {"timestamp": 2.1, "lane": 1, "type": "TAP"},
        ]
    }
    spawner.start_spawning_sequence(chart)

    # Spawn both notes
    spawner.update(1.0)  # Both within approach window
    assert spawner.get_active_count() == 2

    # Advance past hit time → both retire
    spawner.update(3.0)  # Well past both hit times
    assert spawner.get_active_count() == 0

    # Spawn again → pool elements should be reused
    chart2 = {
        "noteTimeline": [
            {"timestamp": 5.0, "lane": 2, "type": "TAP"},
        ]
    }
    spawner.start_spawning_sequence(chart2)
    spawner.update(4.0)
    assert spawner.get_active_count() == 1


def test_pool_exhaustion_warning():
    spawner = NoteSpawner()
    spawner.preallocate_pool(1)
    chart = {
        "noteTimeline": [
            {"timestamp": 2.0, "lane": 0, "type": "TAP"},
            {"timestamp": 2.01, "lane": 1, "type": "TAP"},
            {"timestamp": 2.02, "lane": 2, "type": "TAP"},
        ]
    }
    spawner.start_spawning_sequence(chart)
    spawner.update(1.0)  # Only 1 can spawn, rest trigger exhaustion warning
    assert spawner.get_pool_exhaustion_warnings() >= 1


# ── Note expiration ────────────────────────────────────────────────────────────


def test_is_note_expired_after_hit_time():
    spawner = NoteSpawner()
    spawner.preallocate_pool(10)
    chart = {"noteTimeline": [{"timestamp": 1.0, "lane": 0, "type": "TAP"}]}
    spawner.start_spawning_sequence(chart)

    assert spawner.is_note_expired(0, 0.5) is False
    assert spawner.is_note_expired(0, 1.5) is True


def test_is_note_expired_invalid_index():
    spawner = NoteSpawner()
    spawner.preallocate_pool(10)
    chart = {"noteTimeline": []}
    spawner.start_spawning_sequence(chart)
    assert spawner.is_note_expired(0, 1.0) is False