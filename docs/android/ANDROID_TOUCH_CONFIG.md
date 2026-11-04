# ANDROID TOUCH INPUT CONFIGURATION — PROJECT RHYTHM (Agent 07)

Documents touch input handling for Android devices, including deadzone
configuration, multitouch handling, and touch-to-lane mapping.

## Touch Input Architecture

Touch input flows: Device touchscreen → Godot InputEventScreenTouch →
LaneManager._input() → ScoreManager.process_action_input() → Judgment.

## Touch Deadzone

| Setting | Default | Purpose |
|---------|---------|---------|
| TOUCH_DEADZONE_RADIUS | 8.0 pixels | Rejects taps near lane boundaries to prevent accidental adjacent-lane input |
| DEBOUNCE_SECONDS | 0.08 | 80 ms minimum between same-lane taps to prevent double-scoring |

### Deadzone Behavior

The deadzone is a region within `touch_deadzone_radius` pixels of either lane
edge. Taps in this region are flagged as ambiguous and can be rejected by the
gameplay layer to avoid accidental adjacent-lane input on mobile touchscreens.

| Caller | Method | Purpose |
|--------|--------|---------|
| LaneManager._input() | is_tap_in_deadzone() | Check if tap is near lane boundary |
| GameScene | — | Consumes is_tap_in_deadzone() result to suppress ambiguous taps |

## Lane Mapping

| Input | Mapping Logic |
|-------|---------------|
| Touch X coordinate | Mapped to lane index via `get_lane_index_for_x(screen_x)` |
| Lane width | `screen_width / lane_count` |
| Valid lane range | `[0, lane_count - 1]` |
| Out-of-range X | Returns -1 (no lane) |

For 4-lane MVP on a 1920px-wide screen:
| Lane | X Range (px) |
|------|--------------|
| 0 | 0 — 479 |
| 1 | 480 — 959 |
| 2 | 960 — 1439 |
| 3 | 1440 — 1919 |

## Multitouch Handling

| Behavior | Implementation |
|----------|----------------|
| Multiple lanes simultaneously | Each InputEventScreenTouch handled independently |
| Same lane rapid taps | Debounced at 80 ms (DEBOUNCE_SECONDS) |
| Touch up events | Return None (no scoring on release) |
| Input gating | Disabled when `input_enabled == false` (pause, results, menu) |

## Mobile Aspect Ratio Handling

| Screen Width | HUD Behavior |
|--------------|--------------|
| >= 640 px | Full HUD: score, combo, accuracy, song title, progress bar, time remaining |
| 480–639 px | Song title hidden; accuracy shifted right |
| < 480 px | Accuracy and combo hidden; score font shrunk to 14–20px |

## Implementation Files

| File | Role |
|------|------|
| godot_project/scripts/LaneManager.gd | Touch input parsing, lane mapping, deadzone, debounce |
| godot_project/scripts/GameScene.gd | Touch → ScoreManager wiring, HUD updates |
| godot_project/scripts/core/GameConfig.gd | Default lane count (4), allowed lane counts ([4, 6]) |
| android/EXPORT_PRESET.md | Android export preset configuration |
| android/EXPORT_PRESET_RELEASE.md | Release preset configuration |

## Testing

No device or emulator is available (B-04). Touch input behavior is validated
through pure-Python unit tests in tests/unit/test_lane_manager.py and
tests/unit/test_lane_manager_boundary.py, which verify lane mapping,
deadzone configuration, and edge-case handling without Godot execution.
