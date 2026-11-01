"""Shared fixtures and path constants for the QA test suite.

Mirrors the layout of tests/test_game_config.py: ROOT is the repository root
and CHART_PATH points at charts/example_chart.json, which ships in this
worktree (laneCount 4, lanes 0-3, TAP/HOLD notes).
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
CHART_PATH = ROOT / "charts" / "example_chart.json"

LANE_COUNT = 4
SIX_LANE_COUNT = 6


def load_chart() -> dict:
    return json.loads(CHART_PATH.read_text(encoding="utf-8"))


@pytest.fixture
def chart() -> dict:
    return load_chart()


@pytest.fixture
def lane_count() -> int:
    return LANE_COUNT


@pytest.fixture
def six_lane_count() -> int:
    return SIX_LANE_COUNT
