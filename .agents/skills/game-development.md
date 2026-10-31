# Skill: Game Development — 2D Rhythm Game Architecture

Purpose: Build and maintain the core 2D rhythm-game systems (tile spawning, lanes, game states, object pooling) for PROJECT RHYTHM in Godot 4 GDScript.

## Scope

- Godot 4 scene/node architecture
- Node2D/CanvasLayer layout for gameplay
- Game-state machine (menu → gameplay → pause → results)
- Object pool for visual note tiles (no runtime instantiation)
- Lane partitioning and judgment-line positioning

## Procedure: Add a new gameplay lane

1. Open `godot_project/scenes/GameScene.tscn`.
2. Update `LaneManager.gd` `column_width_step` calculation (already viewport-relative: screen_width / lane_count).
3. Change `lane_count` default (currently 6) — MVP uses 4; foundation supports 6.
4. Clamp touch lane index `clampi(lane, 0, lane_count - 1)` in LaneManager._input.
5. Regenerate any lane-boundary debug visuals in LaneDividers.
6. Update ChartLoader laneCount expectation in chart metadata.
7. Test touch-to-lane mapping across all lanes on target device.

## Procedure: Spawn notes from a chart (object pool)

1. ChartLoader loads JSON chart into `current_chart["noteTimeline"]` (sorted by timestamp).
2. NoteSpawner.preallocate_memory_pool() creates MAX_POOL_LIMIT ColorRect nodes at scene load, hidden.
3. On gameplay start, NoteSpawner.start_spawning_sequence(chart_data) resets the timeline index.
4. Each _process frame: while next note timestamp - APPROACH_TIME <= playback_time, deploy a pool element via _deploy_pool_element.
5. _synchronize_active_elements computes tile Y from `(playback_time - hit_time + APPROACH_TIME) / APPROACH_TIME * drop_dist`.
6. Retire tiles past judgment_y + 60 px via _retire_tile.
7. No new nodes are created during gameplay (pool exhausted → warning).

## Example: TAP vs HOLD tile visuals (NoteSpawner._configure_tile_visual)

- TAP: color #e91e63 (pink), fixed height 24 px.
- HOLD: color #29b6f6 (cyan), height scaled by duration/APPROACH_TIME * drop_dist, bottom-anchored at judgment line.

## Acceptance criteria

- [ ] Tiles spawn ahead of hit time within APPROACH_TIME window
- [ ] Tile Y position matches audio-clock playback time (no frame-delta drift)
- [ ] Object pool never instantiates nodes during gameplay
- [ ] Lane count is configurable; 4-lane MVP works
- [ ] Tiles retire cleanly past judgment line (no orphaned nodes)

## Files owned

- godot_project/scripts/LaneManager.gd
- godot_project/scripts/NoteSpawner.gd
- godot_project/scripts/ChartLoader.gd
- godot_project/scenes/GameScene.tscn
