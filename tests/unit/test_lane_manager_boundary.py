"""Additional LaneManager boundary tests for edge cases.

Extends tests/unit/test_lane_manager.py with focused coverage for:
- Touch at exact playfield edges
- Lane boundary touches
- Touch deadzone behavior
"""

from __future__ import annotations

import pytest

from tests.unit.lane_manager import LaneConfig, LaneManager


# ── Lane boundary mapping ───────────────────────────────────────────────────


def test_lane_zero_at_left_edge_exactly():
    lm = LaneManager()
    assert lm.get_lane_index_for_x(0.0) == 0


def test_last_lane_at_right_edge_exactly():
    lm = LaneManager()
    width = lm.get_lane_width()
    right_edge = lm.config.screen_width - 0.001  # just inside right edge
    assert lm.get_lane_index_for_x(right_edge) == 3


def test_lane_boundaries_are_consistent():
    """Lane index at exact column boundaries maps to the right lane."""
    lm = LaneManager()
    width = lm.get_lane_width()
    # Boundary between lane 0 and lane 1
    assert lm.get_lane_index_for_x(width) == 1
    # Just before boundary, still lane 0
    assert lm.get_lane_index_for_x(width - 0.001) == 0
    # Boundary between lane 2 and lane 3
    assert lm.get_lane_index_for_x(2 * width) == 2
    assert lm.get_lane_index_for_x(2 * width - 0.001) == 1


def test_outside_playfield_returns_minus_one():
    lm = LaneManager()
    width = lm.get_lane_width()
    # Far left
    assert lm.get_lane_index_for_x(-width) == -1
    # Far right
    assert lm.get_lane_index_for_x(4 * width + 1.0) == 3


def test_lane_left_edges_for_all_lanes():
    lm = LaneManager()
    width = lm.get_lane_width()
    for i in range(4):
        assert lm.get_lane_left_edge(i) == i * width


# ── Touch deadzone ──────────────────────────────────────────────────────────


def test_deadzone_default_is_8_pixels():
    lm = LaneManager()
    assert lm.get_touch_deadzone_radius() == 8.0


def test_set_touch_deadzone_changes_radius():
    lm = LaneManager()
    lm.set_touch_deadzone(16.0)
    assert lm.get_touch_deadzone_radius() == 16.0


def test_set_touch_deadzone_negative_clamped_to_zero():
    lm = LaneManager()
    lm.set_touch_deadzone(-5.0)
    assert lm.get_touch_deadzone_radius() == 0.0


def test_deadzone_zero_allows_edge_taps():
    lm = LaneManager()
    lm.set_touch_deadzone(0.0)
    assert lm.is_tap_in_deadzone(0.0, 0) is False


def test_deadzone_flags_edge_adjacent_taps():
    lm = LaneManager()
    width = lm.get_lane_width()
    lane_0_center = lm.get_lane_left_edge(0) + width * 0.5
    # Tap very close to left edge of lane 1 (right edge of lane 0)
    boundary = lm.get_lane_left_edge(1)
    assert lm.is_tap_in_deadzone(boundary - 1.0, 0) is True
    assert lm.is_tap_in_deadzone(boundary - 1.0, 1) is True
    # Tap at center of lane 0 is NOT in deadzone
    assert lm.is_tap_in_deadzone(lane_0_center, 0) is False


# ── Lane geometry ───────────────────────────────────────────────────────────


def test_lane_count_four_has_four_left_edges():
    lm = LaneManager()
    edges = [lm.get_lane_left_edge(i) for i in range(4)]
    assert edges == [0.0, lm.get_lane_width(), 2 * lm.get_lane_width(), 3 * lm.get_lane_width()]
