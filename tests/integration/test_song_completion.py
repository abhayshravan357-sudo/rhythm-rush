"""Integration tests for the song completion flow.

Validates the complete pipeline:
Chart Loading -> Game Init -> Tile Scheduling -> Lane Input -> Hit Detection ->
Scoring -> Completion (audio stops, results state).
"""

from __future__ import annotations

import json
from pathlib import Path

from tests.unit.game_controller import GameController
from tests.unit.lane_manager import LaneManager
from tests.unit.note_spawner import NoteSpawner
from tests.unit.scoring_engine import ScoringEngine

ROOT = Path(__file__).resolve().parents[2]
CHART_PATH = ROOT / "charts" / "example_chart.json"


def _load_chart() -> dict:
    return json.loads(CHART_PATH.read_text(encoding="utf-8"))


def test_full_song_completion_perfect_playthrough():
    gc = GameController()
    gc.prepare_song("example_track", "res://charts/example_chart.json")
    gc.start_song()

    lm = LaneManager()
    lm.set_input_enabled(True)

    scoring = ScoringEngine()
    chart = _load_chart()
    notes = chart["noteTimeline"]
    scoring.reset(notes)

    spawner = NoteSpawner()
    spawner.preallocate_pool(200)
    spawner.start_spawning_sequence(chart)

    for note in notes:
        playback_time = float(note["timestamp"])
        lane = int(note["lane"])

        # Spawner syncs to the playback clock.
        spawner.update(playback_time)

        # Lane input maps to the correct lane.
        mapped_lane = lm.get_lane_index_for_x(100.0 + lane * lm.get_lane_width() + 10.0)
        assert mapped_lane == lane

        # Hit detection at exact hit time -> PERFECT.
        rating = scoring.tap(playback_time, lane)
        assert rating == "PERFECT", f"note at {playback_time}s lane {lane} got {rating}"

    gc.complete_song()
    assert gc.state_manager.current_state == "RESULTS"
    assert gc.audio_sync.active is False
    assert scoring.resolved_count == scoring.total
    assert scoring.sequence_complete is True
    assert scoring.combo == scoring.total  # all hits, no misses
    assert scoring.score > 0


def test_full_song_completion_all_misses():
    gc = GameController()
    gc.prepare_song("example_track", "res://charts/example_chart.json")
    gc.start_song()

    scoring = ScoringEngine()
    chart = _load_chart()
    notes = chart["noteTimeline"]
    scoring.reset(notes)

    spawner = NoteSpawner()
    spawner.preallocate_pool(200)
    spawner.start_spawning_sequence(chart)

    # Never tap; every note drifts past its hit time -> miss.
    for index, note in enumerate(notes):
        playback_time = float(note["timestamp"])
        spawner.update(playback_time + 0.2)  # past hit time
        scoring.register_miss(index)

    gc.complete_song()
    assert scoring.resolved_count == scoring.total
    assert scoring.combo == 0  # all misses, combo reset
    assert scoring.score == 0  # no points
    assert gc.state_manager.current_state == "RESULTS"


def test_song_completion_enters_results_and_stops_audio():
    gc = GameController()
    gc.prepare_song("song1", "res://charts/song1.json")
    gc.start_song()
    assert gc.audio_sync.active is True
    gc.complete_song()
    assert gc.is_game_active is False
    assert gc.state_manager.current_state == "RESULTS"
    assert gc.audio_sync.active is False
