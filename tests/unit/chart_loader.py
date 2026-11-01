"""Pure-Python reference implementation of ChartLoader JSON IO and validation.

Mirrors godot_project/scripts/ChartLoader.gd (load_chart, get_notes_in_window,
get_metadata) plus schema validation used to accept/reject a chart payload.
No Godot FileAccess/JSON is used; the standard library parses the JSON.
"""

from __future__ import annotations

import json
from pathlib import Path

REQUIRED_ROOT_KEYS = ("metaData", "noteTimeline")
VALID_NOTE_TYPES = {"TAP", "HOLD", "SIMULTANEOUS"}


def load_chart(path) -> dict:
    """Load and validate a chart JSON file. Returns {} on any failure."""
    path = Path(path)
    if not path.exists():
        return {}
    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
    except (OSError, ValueError, json.JSONDecodeError):
        return {}
    if not isinstance(data, dict):
        return {}
    if not all(key in data for key in REQUIRED_ROOT_KEYS):
        return {}
    timeline = list(data.get("noteTimeline") or [])
    try:
        timeline.sort(key=lambda note: float(note["timestamp"]))
    except (KeyError, TypeError, ValueError):
        return {}
    data["noteTimeline"] = timeline
    return data


def get_notes_in_window(chart: dict, time_start: float, time_end: float) -> list:
    """Return all notes whose timestamps fall within [time_start, time_end]."""
    if not chart:
        return []
    return [
        note
        for note in chart.get("noteTimeline", [])
        if time_start <= float(note["timestamp"]) <= time_end
    ]


def get_metadata(chart: dict) -> dict:
    if not chart:
        return {}
    return chart.get("metaData", {})


def validate_chart_schema(chart: dict, lane_count: int) -> list:
    """Return a list of human-readable schema violations (empty = valid)."""
    errors: list[str] = []
    if not isinstance(chart, dict):
        return ["chart root is not a dictionary"]
    if "metaData" not in chart:
        errors.append("missing required root key: metaData")
    if "noteTimeline" not in chart:
        errors.append("missing required root key: noteTimeline")
    if errors:
        return errors

    meta = chart["metaData"]
    if not isinstance(meta, dict):
        errors.append("metaData must be a dictionary")
    else:
        declared = meta.get("laneCount")
        if not isinstance(declared, (int, float)) or int(declared) <= 0:
            errors.append("metaData.laneCount must be a positive integer")
        elif int(declared) != lane_count:
            errors.append(f"metaData.laneCount {declared} != expected {lane_count}")

    timeline = chart["noteTimeline"]
    if not isinstance(timeline, list):
        errors.append("noteTimeline must be a list")
        return errors

    timestamps = []
    for index, note in enumerate(timeline):
        prefix = f"note[{index}]"
        if not isinstance(note, dict):
            errors.append(f"{prefix} is not a dictionary")
            continue
        lane = note.get("lane")
        if not isinstance(lane, (int, float)) or not (0 <= int(lane) < lane_count):
            errors.append(f"{prefix} lane {lane!r} out of range [0, {lane_count})")
        kind = note.get("type")
        if kind not in VALID_NOTE_TYPES:
            errors.append(f"{prefix} type {kind!r} not in {sorted(VALID_NOTE_TYPES)}")
        try:
            ts = float(note["timestamp"])
        except (KeyError, TypeError, ValueError):
            errors.append(f"{prefix} missing/invalid timestamp")
            continue
        if ts < 0:
            errors.append(f"{prefix} timestamp {ts} is negative")
        timestamps.append(ts)

    if timestamps != sorted(timestamps):
        errors.append("noteTimeline is not in chronological order")

    return errors
