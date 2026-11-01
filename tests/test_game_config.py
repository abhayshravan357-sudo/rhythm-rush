import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHART_PATH = ROOT / "charts" / "example_chart.json"


def test_example_chart_metadata_uses_supported_lane_count():
    payload = json.loads(CHART_PATH.read_text(encoding="utf-8"))
    assert "metaData" in payload
    assert payload["metaData"].get("laneCount") == 4


def test_example_chart_note_lanes_are_in_range_for_mvp():
    payload = json.loads(CHART_PATH.read_text(encoding="utf-8"))
    lane_count = int(payload["metaData"].get("laneCount", 4))
    for note in payload["noteTimeline"]:
        assert 0 <= int(note["lane"]) < lane_count
        assert note["type"] in {"TAP", "HOLD", "SIMULTANEOUS"}


def test_example_chart_timestamps_are_positive():
    payload = json.loads(CHART_PATH.read_text(encoding="utf-8"))
    for note in payload["noteTimeline"]:
        assert float(note["timestamp"]) >= 0.0
