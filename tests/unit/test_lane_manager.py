"""Unit tests for LaneManager reference implementation (lane_manager.py).

Tests four-lane mapping, lane boundaries, touch-to-lane mapping, input gating,
and valid/invalid states. Mirrors godot_project/scripts/LaneManager.gd behavior.
"""

from __future__ import annotations

import pytest

from tests.unit.lane_manager import LaneConfig, LaneManager


# ── Construction and defaults ──────────────────────────────────────────────────


def test_defaults_are_four_lanes():
    lm = LaneManager()
    assert lm.get_lane_count() == 4


def test_judgment_line_at_85_percent():
    lm = LaneManager()
    expected_y = 1080.0 * 0.85
    assert lm.get_judgment_line_y() == expected_y


def test_column_width_step():
    lm = LaneManager()
    assert lm.get_lane_width() == 1920.0 / 4.0


# ── Lane count normalization ───────────────────────────────────────────────────


def test_lane_count_below_four_clamped_to_four():
    lm = LaneManager(LaneConfig(lane_count=2))
    assert lm.get_lane_count() == 4


def test_lane_count_above_six_clamped_to_six():
    lm = LaneManager(LaneConfig(lane_count=8))
    assert lm.get_lane_count() == 6


def test_six_lane_accepted():
    lm = LaneManager(LaneConfig(lane_count=6))
    assert lm.get_lane_count() == 6


# ── Touch-to-lane mapping ──────────────────────────────────────────────────────


def test_lane_zero_at_left_edge():
    lm = LaneManager()
    assert lm.get_lane_index_for_x(0.0) == 0


def test_lane_one_at_quarter_width():
    lm = LaneManager()
    assert lm.get_lane_index_for_x(lm.get_lane_width()) == 1


def test_lane_three_at_right_edge():
    lm = LaneManager()
    assert lm.get_lane_index_for_x(1919.0) == 3


def test_negative_x_returns_minus_one():
    lm = LaneManager()
    assert lm.get_lane_index_for_x(-1.0) == -1


def test_x_beyond_right_edge_maps_to_last_lane():
    lm = LaneManager()
    assert lm.get_lane_index_for_x(9999.0) == 3


# ── Lane geometry ──────────────────────────────────────────────────────────────


def test_lane_left_edges_are_evenly_spaced():
    lm = LaneManager()
    width = lm.get_lane_width()
    for i in range(4):
        assert lm.get_lane_left_edge(i) == i * width


# ── Input gating ───────────────────────────────────────────────────────────────


def test_input_disabled_by_default():
    lm = LaneManager()
    assert lm.is_input_enabled() is False


def test_process_touch_returns_none_when_input_disabled():
    lm = LaneManager()
    assert lm.process_touch(100.0, pressed=True) is None


def test_process_touch_returns_lane_when_enabled():
    lm = LaneManager()
    lm.set_input_enabled(True)
    assert lm.process_touch(100.0, pressed=True) == 0


def test_process_touch_touch_up_returns_none():
    lm = LaneManager()
    lm.set_input_enabled(True)
    assert lm.process_touch(100.0, pressed=False) is None


def test_set_input_enabled_toggles():
    lm = LaneManager()
    lm.set_input_enabled(True)
    assert lm.is_input_enabled() is True
    lm.set_input_enabled(False)
    assert lm.is_input_enabled() is False