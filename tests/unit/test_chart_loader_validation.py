"""Additional ChartLoader validation tests for invalid lane rejection.

Extends tests/unit/test_chart_loader.py with focused coverage for lane
index rejection: notes with lane >= laneCount, negative lane indices,
and mixed valid/invalid lane sets in a single chart.
"""

from __future__ import annotations

import pytest

from tests.unit.chart_loader import validate_chart_schema


def test_schema_rejects_lane_equal_to_lane_count(lane_count):
    """Lane index equal to laneCount is out of range (0-based indexing)."""
    bad = {
        "metaData": {"laneCount": lane_count},
        "noteTimeline": [{"timestamp": 0.5, "lane": lane_count, "type": "TAP"}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("out of range" in e for e in errors)


def test_schema_rejects_negative_lane_index(lane_count):
    """Negative lane indices are always rejected."""
    bad = {
        "metaData": {"laneCount": lane_count},
        "noteTimeline": [{"timestamp": 0.5, "lane": -1, "type": "TAP"}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("out of range" in e for e in errors)


def test_schema_rejects_multiple_out_of_range_lanes(lane_count):
    """Multiple notes with out-of-range lanes each produce an error."""
    bad = {
        "metaData": {"laneCount": lane_count},
        "noteTimeline": [
            {"timestamp": 0.1, "lane": lane_count, "type": "TAP"},
            {"timestamp": 0.2, "lane": lane_count + 1, "type": "TAP"},
            {"timestamp": 0.3, "lane": lane_count + 2, "type": "TAP"},
        ],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert len([e for e in errors if "out of range" in e]) == 3


def test_schema_accepts_all_valid_lanes(lane_count):
    """All lanes 0..laneCount-1 are accepted for both 4-lane and 6-lane."""
    notes = [
        {"timestamp": float(i) * 0.1, "lane": i % lane_count, "type": "TAP"}
        for i in range(lane_count * 2)
    ]
    bad = {
        "metaData": {"laneCount": lane_count},
        "noteTimeline": notes,
    }
    errors = validate_chart_schema(bad, lane_count)
    assert errors == [], f"Unexpected lane errors: {errors}"


def test_schema_rejects_hold_note_out_of_range_lane(lane_count):
    """HOLD notes with out-of-range lane are also rejected."""
    bad = {
        "metaData": {"laneCount": lane_count},
        "noteTimeline": [{"timestamp": 0.5, "lane": lane_count, "type": "HOLD", "duration": 0.4}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("out of range" in e for e in errors)


def test_schema_rejects_simultaneous_out_of_range_lane(lane_count):
    """SIMULTANEOUS notes with out-of-range lane are also rejected."""
    bad = {
        "metaData": {"laneCount": lane_count},
        "noteTimeline": [{"timestamp": 0.5, "lane": lane_count, "type": "SIMULTANEOUS"}],
    }
    errors = validate_chart_schema(bad, lane_count)
    assert any("out of range" in e for e in errors)
