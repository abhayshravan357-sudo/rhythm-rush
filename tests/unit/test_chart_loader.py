"""Unit tests for chart loading/validation via the ChartLoader schema.

Verifies the pure-Python reference implementation of ChartLoader.gd
(load_chart, get_notes_in_window, get_metadata) plus schema validation
against charts/example_chart.json (laneCount 6, lanes 0-5, TAP/HOLD) and
synthetic invalid payloads. No Godot FileAccess/JSON is used.
"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

import pytest

from tests.unit.chart_loader import (
    VALID_NOTE_TYPES,
    get_metadata,
    get_notes_in_window,
    load_chart,
    validate_chart_schema,
)


def write_temp_chart(payload: dict) -> Path:
    handle = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    json.dump(payload, handle)
    handle.close()
    return Path(handle.name)


# ── Valid chart loading ───────────────────────────────────────────────────────


def test_load_chart_returns_parsed_dict(chart):
    assert isinstance(chart, dict)
    assert chart.get("metaData")
    assert isinstance(chart.get("noteTimeline"), list)
    assert len(chart["noteTimeline"]) > 0


def test_load_chart_metadata_and_lane_count(chart):
    meta = chart["metaData"]
    assert meta["laneCount"] == 6
    assert meta["songName"] == "example_track"
    assert meta["bpm"] == 128.0


def test_load_chart_note_count(chart):
    assert len(chart["noteTimeline"]) == 43


# ── Schema validation on the shipped example chart ────────────────────────────


def test_example_chart_passes_schema(chart, lane_count):
    errors = validate_chart_schema(chart, lane_count)
    assert errors == [], f"schema violations: {errors}"


def test_example_chart_lanes_in_range(chart, lane_count):
    errors = validate_chart_schema(chart, lane_count)
    lane_errors = [e for e in errors if "lane" in e and "out of range" in e]
    assert lane_errors == []
    for note in chart["noteTimeline"]:
        assert 0 <= int(note["lane"]) < lane_count


def test_example_chart_note_types_valid(chart):
    for note in chart["noteTimeline"]:
        assert note["type"] in VALID_NOTE_TYPES


def test_example_chart_timestamps_positive(chart):
    for note in chart["noteTimeline"]:
        assert float(note["timestamp"]) >= 0.0


def test_example_chart_chronological(chart):
    timestamps = [float(n["timestamp"]) for n in chart["noteTimeline"]]
    assert timestamps == sorted(timestamps)


# ── get_notes_in_window / get_metadata ────────────────────────────────────────


def test_get_notes_in_window_filters_inclusive(chart):
    first_ts = float(chart["noteTimeline"][0]["timestamp"])
    last_ts = float(chart["noteTimeline"][-1]["timestamp"])
    inside = get_notes_in_window(chart, first_ts, last_ts)
    assert len(inside) == len(chart["noteTimeline"])

    before = get_notes_in_window(chart, -1.0, first_ts - 0.001)
    assert before == []

    after = get_notes_in_window(chart, last_ts + 0.001, last_ts + 10.0)
    assert after == []

    mid_start = first_ts + 0.5
    mid_end = first_ts + 1.0
    slice_notes = get_notes_in_window(chart, mid_start, mid_end)
    for note in slice_notes:
        assert mid_start <= float(note["timestamp"]) <= mid_end


def test_get_notes_in_window_empty_when_no_chart():
    assert get_notes_in_window({}, 0.0, 1.0) == []


def test_get_metadata_returns_meta(chart):
    meta = get_metadata(chart)
    assert meta == chart["metaData"]
    assert meta["laneCount"] == 6


def test_get_metadata_empty_when_no_chart():
    assert get_metadata({}) == {}


# ── Failure modes ─────────────────────────────────────────────────────────────


def test_load_chart_missing_file_returns_empty():
    assert load_chart(Path("/nonexistent/path/to/chart.json")) == {}


def test_load_chart_invalid_json_returns_empty():
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
        handle.write("{ not valid json")
        path = Path(handle.name)
    assert load_chart(path) == {}


def test_load_chart_root_not_dict_returns_empty():
    path = write_temp_chart([1, 2, 3])
    assert load_chart(path) == {}


def test_load_chart_missing_required_keys_returns_empty():
    path = write_temp_chart({"metaData": {}})
    assert load_chart(path) == {}
    path = write_temp_chart({"noteTimeline": []})
    assert load_chart(path) == {}


# ── Schema rejection cases ────────────────────────────────────────────────────


def test_schema_rejects_lane_out_of_range(chart, lane_count):
    bad = {
        "metaData": dict(chart["metaData"], laneCount=lane_count),
        "noteTimeline": [{"timestamp": 0.5, "lane": lane_count, "type": "TAP"}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("out of range" in e for e in errors)


def test_schema_rejects_invalid_note_type(chart, lane_count):
    bad = {
        "metaData": dict(chart["metaData"], laneCount=lane_count),
        "noteTimeline": [{"timestamp": 0.5, "lane": 0, "type": "SLIDE"}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("type" in e for e in errors)


def test_schema_rejects_negative_timestamp(chart, lane_count):
    bad = {
        "metaData": dict(chart["metaData"], laneCount=lane_count),
        "noteTimeline": [{"timestamp": -0.5, "lane": 0, "type": "TAP"}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("negative" in e for e in errors)


def test_schema_rejects_non_chronological(chart, lane_count):
    bad = {
        "metaData": dict(chart["metaData"], laneCount=lane_count),
        "noteTimeline": [
            {"timestamp": 1.0, "lane": 0, "type": "TAP"},
            {"timestamp": 0.5, "lane": 1, "type": "TAP"},
        ],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("chronological" in e for e in errors)


def test_schema_rejects_missing_root_keys():
    errors = validate_chart_schema({"metaData": {"laneCount": 4}}, 4)
    assert any("noteTimeline" in e for e in errors)
    errors = validate_chart_schema({"noteTimeline": []}, 4)
    assert any("metaData" in e for e in errors)
