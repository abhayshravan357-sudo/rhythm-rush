# MVP-03 Gameplay Input & Judgment Refinement

Refines lane input handling, duplicate-input prevention, simultaneous/rapid input
handling, note lifecycle, missed-note processing, and input-latency tracking for
the gameplay input/judgment pipeline. Preserves 4-lane MVP functionality and
6-lane compatibility.

## Scope

- `godot_project/scripts/LaneManager.gd` — lane input handling, duplicate-input
  prevention, simultaneous/rapid input handling, per-lane touch tracking.
- `godot_project/scripts/NoteSpawner.gd` — note lifecycle (incl. HOLD sustain),
  missed-note processing, input-latency tracking.
- `docs/gameplay/MVP03_INPUT_AND_JUDGMENT.md` (this document).

## LaneManager.gd

### Responsibilities

- Partition the viewport into `lane_count` columns (MVP = 4; foundation supports
  6 via `GameConfig.ALLOWED_LANE_COUNTS`).
- Map screen X positions to lane indices (`get_lane_index_for_x`).
- Gate all touch input behind `input_enabled` (controlled by the gameplay state
  machine).
- Emit `column_touch_down(lane_index)` / `column_touch_up(lane_index)` signals.
- Expose judgment-line geometry to NoteSpawner/ScoreManager.

### New input-handling behavior

| Concern | Implementation |
|---|---|
| Duplicate-input prevention | Per-lane cooldown (`INPUT_COOLDOWN_SECONDS = 0.05s`). A second tap on the same lane within the window is ignored. |
| Simultaneous input | Per-lane `_active_touches` map (lane → touch finger id). Different lanes are tracked independently; a second finger on an already-active lane is ignored until released. |
| Rapid-input handling | Cooldown + active-touch guard combine to reject rapid double-taps on one lane while still allowing taps across different lanes. |
| Input gating | `_on_column_touch_down` guards with `GameStateManager.is_playing()` before calling `ScoreManager.process_action_input`. |
| Touch lifecycle | `_input` adds/removes the lane from `_active_touches` on press/release so releases only clear the matching finger. |

### Signals

- `column_touch_down(lane_index: int)` — accepted finger down on a lane (after
  cooldown/active-touch checks). Connected in `_ready` to `_on_column_touch_down`
  which gates on `is_playing()` then calls `ScoreManager.process_action_input`.
- `column_touch_up(lane_index: int)` — finger up on a lane. Reserved for HOLD
  release handling (future MVP); currently releases active-touch tracking only.

### Public API

| Method | Purpose |
|---|---|
| `set_input_enabled(enabled)` | Enable/disable all touch input. |
| `is_input_enabled()` | Current gate state. |
| `get_lane_count()` | Normalized lane count (4 for MVP). |
| `get_lane_width()` | Viewport width / lane count. |
| `get_lane_left_edge(lane_index)` | Left edge X of a lane. |
| `get_lane_index_for_x(screen_x)` | Lane index for screen X, clamped [0, lane_count). |
| `get_judgment_line_y()` | Y of the hit line (85% of screen height). |
| `get_total_drop_distance()` | Drop distance from spawn (y=0) to judgment line. |

### Input flow

1. `_input(event)` returns early unless `input_enabled` is true.
2. `InputEventScreenTouch` → `get_lane_index_for_x(event.position.x)`; skip if `< 0`.
3. On press: reject if lane already has an active touch (simultaneous same-lane
   guard) or if within `INPUT_COOLDOWN_SECONDS` of the last accepted tap on that
   lane (duplicate guard). Otherwise record the touch, update last-tap time, and
   emit `column_touch_down`.
4. On release: clear the lane's active touch if the finger id matches, then emit
   `column_touch_up`.
5. `_on_column_touch_down(lane)` → if `GameStateManager.is_playing()` →
   `ScoreManager.process_action_input(lane)`.

### Defect fixed

- Previously `column_touch_down` was bound **directly** to
  `ScoreManager.process_action_input` in `_ready`, bypassing the
  `GameStateManager.is_playing()` gate that `_on_column_touch_down` (dead,
  unconnected code) was meant to provide. The signal is now bound to
  `_on_column_touch_down`, which is the single gated entry point to
  `ScoreManager.process_action_input`.

## NoteSpawner.gd

### Responsibilities

- Pre-allocate a fixed pool of `ColorRect` nodes at scene load (no `new`/`instance`
  during gameplay).
- Drive note spawning from a chart `noteTimeline` using the authoritative audio
  clock (`AudioSync.adjusted_system_time`).
- Animate notes falling toward the judgment line each frame.
- Retire and recycle pool elements once notes scroll past the judgment line.

### New behavior

| Concern | Implementation |
|---|---|
| HOLD note sustain | HOLD notes are bottom-anchored (`y = calc_y - tile.size.y`) and sustained until `playback_time > hit_time + duration`, then retired. Previously HOLD notes retired purely on position past the judgment line. |
| Missed-note processing | `_process_expired_notes` marks timeline notes whose `hit_time + RETIRE_GRACE_SECONDS` has passed as judged (`_judged_note_indices`) so they are not re-evaluated by the spawner. ScoreManager independently registers the scoring miss in its own `_process` pass (`playback_time > hit_time + HIT_WINDOW_GOOD`). |
| Input-latency tracking | Each deploy samples `AudioSync.adjusted_system_time - hit_time` into `_latency_samples`; `average_input_latency` is recomputed and exposed via `get_average_input_latency()`. This is the spawn-to-hit delta (approach lead); true touch-to-judgment latency is compensated by `AudioSync.local_hardware_offset` applied to `adjusted_system_time`. |

### Constants

- `MAX_POOL_LIMIT = 200` — upper bound on simultaneously active notes.
- `RETIRE_GRACE_SECONDS = 0.15` — seconds past hit time before a note is treated as expired by the spawner.

### Public API

| Method | Purpose |
|---|---|
| `start_spawning_sequence(chart_data)` | Set timeline, reset index, clear actives/judged/latency samples. |
| `get_average_input_latency()` | Mean spawn-to-hit delta (seconds) across deployed notes. |

### Timing model

- Spawn trigger: `playback_time >= hit_time - AudioSync.APPROACH_TIME`
  (`APPROACH_TIME = 1.5s`). Notes whose `hit_time` already passed are skipped
  (never rendered); ScoreManager resolves them as hits/misses.
- Timeline assumed sorted ascending; spawn loop breaks on first not-yet-ready
  note.
- Position: `y = (playback_time - hit_time + APPROACH_TIME) / APPROACH_TIME *
  drop_distance`.
- HOLD notes bottom-anchored; retired at `hit_time + duration`. TAPs top-anchored;
  retired when `tile.position.y > judgment_y + 60.0`.

### Object pooling

- 200 `ColorRect` nodes pre-allocated in `_ready`, hidden, `set_process(false)`.
- `_deploy_pool_element` scans the pool for the first inactive tile.
- `_retire_tile` hides the tile, clears `is_active`, removes from
  `active_rendering_array` for reuse.

### Visuals

- TAP: pink (`#e91e63`), height 24px.
- HOLD: cyan (`#29b6f6`), height scaled by `duration / APPROACH_TIME *
  drop_distance`.
- Width: `lane_width * 0.82`, centered in the lane
  (`left_edge + lane_width * 0.09`).

### Dependencies

- `AudioSync.adjusted_system_time` — authoritative audio-clock playback time
  (offset-calibrated).
- `AudioSync.APPROACH_TIME` — approach window in seconds.
- `lane_manager` (`$"../LaneManager"`) — lane geometry and drop distance.
- Scene: NoteSpawner must be a sibling of LaneManager under a common parent
  (verified in GameScene.tscn).

## Lane-count compatibility

- 4-lane MVP: `GameConfig.DEFAULT_LANE_COUNT = 4`; `normalize_lane_count`
  clamps to `[4, 6]`. All lane geometry scales with `lane_count`, so 6-lane
  charts require no code changes.
- `get_lane_index_for_x` clamps out-of-range X to the last valid lane and
  returns `-1` for negative X, so taps outside the play area never reach
  ScoreManager.

## Integration points

- `GameConfig.DEFAULT_LANE_COUNT = 4`; `normalize_lane_count` clamps to `[4, 6]`.
- `GameStateManager.is_playing()` gates gameplay input.
- `AudioSync` provides `adjusted_system_time` (playback head + time since last
  mix, offset-calibrated) and `APPROACH_TIME`.
- `ScoreManager.process_action_input(lane_index)` consumes `column_touch_down`
  for hit evaluation (single gated entry point via LaneManager).
- `GameScene.gd` wires `AudioSync.initialize_playback_channel($AudioPlayer)` and
  toggles `lane_manager.set_input_enabled` on pause/resume/complete.

## File inventory

| File | Status |
|---|---|
| `godot_project/scripts/LaneManager.gd` | Refined (duplicate prevention, simultaneous input, touch tracking, gated ScoreManager entry) |
| `godot_project/scripts/NoteSpawner.gd` | Refined (HOLD sustain, missed-note processing, input-latency tracking) |
| `docs/gameplay/MVP03_INPUT_AND_JUDGMENT.md` | New (this document) |
| `godot_project/scripts/ScoreManager.gd` | Unchanged (Agent 05-owned; called, not modified) |
| `godot_project/scripts/AudioSync.gd` | Unchanged (authoritative audio clock) |
| `godot_project/scripts/GameScene.gd` | Unchanged |
