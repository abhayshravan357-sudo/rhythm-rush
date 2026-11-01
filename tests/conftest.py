"""Shared fixtures and path constants for the QA test suite.

Mirrors the layout of tests/test_game_config.py: ROOT is the repository root
and CHART_PATH points at charts/example_chart.json, which ships in this
worktree (laneCount 6, lanes 0-5, TAP/HOLD notes).
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
CHART_PATH = ROOT / "charts" / "example_chart.json"

LANE_COUNT = 4


def load_chart() -> dict:
    return json.loads(CHART_PATH.read_text(encoding="utf-8"))


@pytest.fixture
def chart() -> dict:
    return load_chart()


@pytest.fixture
def lane_count() -> int:
    return LANE_COUNT
