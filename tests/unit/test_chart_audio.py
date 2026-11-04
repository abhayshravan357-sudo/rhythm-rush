"""Unit tests for chart audio file binding in GameScene.

Verifies that chart metaData carries an audioFile path and that the referenced
audio file exists at the expected filesystem location. Mirrors the audio
binding performed in godot_project/scripts/GameScene.gd
(_bootstrap_gameplay loads res://assets/audio/<audioFile> and assigns it to
$AudioPlayer.stream before calling AudioSync.initialize_playback_channel).
"""

from __future__ import annotations

from pathlib import Path

import pytest

from tests.unit.chart_loader import get_metadata

ROOT = Path(__file__).resolve().parents[2]
CHART_PATH = ROOT / "charts" / "example_chart.json"
AUDIO_DIR = ROOT / "godot_project" / "assets" / "audio"


def load_chart() -> dict:
    import json

    return json.loads(CHART_PATH.read_text(encoding="utf-8"))


@pytest.fixture
def chart() -> dict:
    return load_chart()


# ── Chart metadata carries audioFile ─────────────────────────────────────────


def test_chart_metadata_has_audiofile(chart):
    meta = get_metadata(chart)
    assert "audioFile" in meta, "chart metaData missing audioFile field"
    assert isinstance(meta["audioFile"], str) and meta["audioFile"], "audioFile must be a non-empty string"


def test_audiofile_matches_example_track(chart):
    meta = get_metadata(chart)
    assert meta["audioFile"] == "example_track.ogg"


# ── Referenced audio file exists on disk ─────────────────────────────────────


def test_audio_file_exists(chart):
    audio_file = get_metadata(chart)["audioFile"]
    audio_path = AUDIO_DIR / audio_file
    assert audio_path.is_file(), f"referenced audio file missing: {audio_path}"


def test_audio_file_has_nonzero_size(chart):
    audio_file = get_metadata(chart)["audioFile"]
    audio_path = AUDIO_DIR / audio_file
    assert audio_path.stat().st_size > 0, f"referenced audio file is empty: {audio_path}"


# ── Resolved audio path matches GameScene binding convention ─────────────────


def test_resolved_audio_path_matches_godot_asset_layout(chart):
    audio_file = get_metadata(chart)["audioFile"]
    expected = AUDIO_DIR / audio_file
    assert expected.name == audio_file
    assert expected.parent == AUDIO_DIR
