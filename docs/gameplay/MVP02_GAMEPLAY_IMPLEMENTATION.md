# MVP-02 Gameplay Implementation

Lane input, note spawning, object pooling, and audio-clock timing for the 4-lane MVP gameplay loop.

## Scope

- `godot_project/scripts/LaneManager.gd` — viewport partitioning, touch-to-lane mapping, input gating, signals.
- `godot_project/scripts/NoteSpawner.gd` — chart-driven scheduling, audio-clock timing, garbage-collection-free object pool.
- Wired into `godot_project/scenes/GameScene.tscn` (LaneManager + NoteSpawner as siblings of GameScene).

## LaneManager.gd

### Responsibilities
- Partition the viewport into `lane_count` columns (MVP = 4; foundation supports 6 via `GameConfig.ALLOWED_LANE_COUNTS`).
- Map screen X positions to lane indices (`get_lane_index_for_x`).
- Gate all touch input behind `input_enabled` (controlled by the gameplay state machine).
- Emit `column_touch_down(lane_index)` / `column_touch_up(lane_index)` signals.
- Expose judgment-line geometry to NoteSpawner/ScoreManager.

### Signals
- `column_touch_down(lane_index: int)` — finger down on a lane. Connected in `_ready` to `ScoreManager.process_action_input`.
- `column_touch_up(lane_index: int)` — finger up on a lane.

### Public API
| Method | Purpose |
|---|---|
| `set_input_enabled(enabled)` | Enable/disable all touch input (state-machine owned). |
| `is_input_enabled()` | Current gate state. |
| `get_lane_count()` | Normalized lane count (4 for MVP). |
| `get_lane_width()` | Viewport width / lane count. |
| `get_lane_left_edge(lane_index)` | Left edge X of a lane. |
| `get_lane_index_for_x(screen_x)` | Lane index for a screen X, clamped [0, lane_count). |
| `get_judgment_line_y()` | Y of the hit line (85% of screen height). |
| `get_total_drop_distance()` | Drop distance from spawn (y=0) to judgment line. |

### Input flow
1. `_input(event)` returns early unless `input_enabled` is true.
2. `InputEventScreenTouch` → `get_lane_index_for_x(event.position.x)` → emit `column_touch_down`/`column_touch_up`.
3. `column_touch_down` is bound to `ScoreManager.process_action_input(lane_index)` for hit/miss evaluation.
4. `_on_column_touch_down` additionally guards with `GameStateManager.is_playing()`.

### Defects / notes
- `_on_column_touch_down` is not connected to any signal (the signal is bound directly to `ScoreManager.process_action_input` in `_ready`). It is dead code but harmless; remove if unused.
- `input_enabled` is the sole gate in `_input`; `_on_column_touch_down` double-checks `is_playing()` but is never invoked.

## NoteSpawner.gd

### Responsibilities
- Pre-allocate a fixed pool of `ColorRect` nodes at scene load (no `new`/`instance` during gameplay).
- Drive note spawning from a chart `noteTimeline` using the authoritative audio clock (`AudioSync.adjusted_system_time`).
- Animate notes falling toward the judgment line each frame.
- Retire and recycle pool elements once notes scroll past the judgment line.

### Constants
- `MAX_POOL_LIMIT = 200` — upper bound on simultaneously active notes. `push_warning` emitted if exhausted.

### Public API
| Method | Purpose |
|---|---|
| `start_spawning_sequence(chart_data)` | Set `tracking_chart_timeline = chart_data["noteTimeline"]`, reset index, clear actives. |

### Timing model
- Spawn trigger: a note enters the visible approach window when `playback_time >= hit_time - AudioSync.APPROACH_TIME` (`APPROACH_TIME = 1.5s`).
- Notes whose `hit_time` already passed are skipped (never rendered); ScoreManager resolves them as hits/misses.
- Timeline is assumed sorted ascending; the spawn loop breaks on the first not-yet-ready note.
- Position: `y = (playback_time - hit_time + APPROACH_TIME) / APPROACH_TIME * drop_distance`.
- HOLD notes are bottom-anchored (`y = calc_y - tile.size.y`); TAPs are top-anchored.
- Retire when `tile.position.y > judgment_y + 60.0`.

### Object pooling
- 200 `ColorRect` nodes pre-allocated in `_ready`, hidden, `set_process(false)`.
- `_deploy_pool_element` scans the pool for the first inactive tile, marks it active, configures visuals, appends to `active_rendering_array`.
- `_retire_tile` hides the tile, clears `is_active`, removes it from `active_rendering_array` for reuse.

### Visuals
- TAP: pink (`#e91e63`), height 24px.
- HOLD: cyan (`#29b6f6`), height scaled by `duration / APPROACH_TIME * drop_distance`.
- Width: `lane_width * 0.82`, centered in the lane (`left_edge + lane_width * 0.09`).

### Dependencies
- `AudioSync.adjusted_system_time` — authoritative audio-clock playback time.
- `AudioSync.APPROACH_TIME` — approach window in seconds.
- `lane_manager` (`$"../LaneManager"`) — lane geometry and drop distance.
- Scene: NoteSpawner must be a sibling of LaneManager under a common parent (verified in GameScene.tscn).

### Defects / notes
- `start_spawning_sequence` reads `chart_data["noteTimeline"]` without a type guard; malformed charts will crash at runtime. ChartLoader is responsible for validating schema upstream.
- `_deploy_pool_element` does a linear pool scan O(MAX_POOL_LIMIT) per spawn; acceptable for MVP scale but worth a free-list if pool pressure grows.
- `lane_manager` is `@onready` resolved via `"../LaneManager"`; breaks if NoteSpawner is reparented outside a sibling relationship with LaneManager.

## Integration points

- `GameConfig.DEFAULT_LANE_COUNT = 4`; `normalize_lane_count` clamps to `[4, 6]`.
- `GameStateManager.is_playing()` gates gameplay input.
- `AudioSync` provides `adjusted_system_time` (playback head + time since last mix, offset-calibrated).
- `ScoreManager.process_action_input(lane_index)` consumes `column_touch_down` for hit evaluation.
- `GameScene.gd` wires `AudioSync.initialize_playback_channel($AudioPlayer)`.

## File inventory

| File | Status |
|---|---|
| `godot_project/scripts/LaneManager.gd` | Existing, tracked, committed |
| `godot_project/scripts/NoteSpawner.gd` | Existing, tracked, committed |
| `godot_project/scenes/GameScene.tscn` | Existing, references both scripts |
| `docs/gameplay/MVP02_GAMEPLAY_IMPLEMENTATION.md` | New (this document) |
