"""Pure-Python reference implementation of LaneManager lane geometry and touch mapping.

Mirrors godot_project/scripts/LaneManager.gd (viewport partitioning, touch-to-lane
mapping, input gating, judgment-line geometry) so lane behavior can be verified
without the Godot engine.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class LaneConfig:
    lane_count: int = 4
    screen_width: float = 1920.0
    screen_height: float = 1080.0
    judgment_line_ratio: float = 0.85  # 85% of screen height


class LaneManager:
    """Reference implementation of LaneManager lane geometry and touch mapping."""

    def __init__(self, config: LaneConfig | None = None):
        self.config = config or LaneConfig()
        self.lane_count = self._normalize_lane_count(self.config.lane_count)
        self.column_width_step = self.config.screen_width / float(self.lane_count)
        self.fixed_judgment_y = self.config.screen_height * self.config.judgment_line_ratio
        self.input_enabled = False
        # MVP-04: touch deadzone radius in pixels.
        self.touch_deadzone_radius: float = 8.0

    def _normalize_lane_count(self, count: int) -> int:
        """Clamp lane count to [4, 6] per GameConfig rules."""
        if count < 4:
            return 4
        if count > 6:
            return 6
        return count

    def set_input_enabled(self, enabled: bool) -> None:
        self.input_enabled = enabled

    def is_input_enabled(self) -> bool:
        return self.input_enabled

    def get_lane_count(self) -> int:
        return self.lane_count

    def get_lane_width(self) -> float:
        return self.column_width_step

    def get_lane_left_edge(self, lane_index: int) -> float:
        target = max(0, min(lane_index, self.lane_count - 1))
        return float(target) * self.column_width_step

    def get_lane_index_for_x(self, screen_x: float) -> int:
        if screen_x < 0.0:
            return -1
        normalized = int(screen_x / self.column_width_step)
        return max(0, min(normalized, self.lane_count - 1))

    def get_judgment_line_y(self) -> float:
        return self.fixed_judgment_y

    def get_total_drop_distance(self) -> float:
        return self.fixed_judgment_y

    def set_touch_deadzone(self, radius_pixels: float) -> None:
        self.touch_deadzone_radius = max(0.0, float(radius_pixels))

    def get_touch_deadzone_radius(self) -> float:
        return self.touch_deadzone_radius

    def is_tap_in_deadzone(self, screen_x: float, lane_index: int) -> bool:
        """Return True if a tap at screen_x is within the deadzone of lane_index boundaries."""
        if self.touch_deadzone_radius <= 0.0:
            return False
        lane_x = float(lane_index) * self.column_width_step
        left_edge = lane_x + 2.0
        right_edge = lane_x + self.column_width_step - 2.0
        if screen_x < left_edge + self.touch_deadzone_radius and screen_x > left_edge - self.touch_deadzone_radius:
            return True
        if screen_x < right_edge + self.touch_deadzone_radius and screen_x > right_edge - self.touch_deadzone_radius:
            return True
        return False

    def process_touch(self, screen_x: float, pressed: bool) -> int | None:
        """Process a touch event. Returns lane index if touch down, None otherwise.

        Input is gated behind input_enabled. Returns -1 for out-of-bounds X.
        """
        if not self.input_enabled:
            return None
        lane = self.get_lane_index_for_x(screen_x)
        if lane < 0:
            return None
        if pressed:
            return lane
        return None