# MVP-03 ARCHITECTURE REVIEW — PROJECT RHYTHM

Project: HexaRhythm
Phase: MVP-03 (Architecture Lifecycle Review)
Coordinator: Agent 01 — Game Architecture Engineer
Branch: agent/project-rhythm-architecture
Worktree: /home/abhaysawant/project-rhythm-architecture
Model: NVIDIA: Nemotron 3.5 Super VL (free), provider: kilo
Date: 2026-11-02

## 1. Scope

Files audited:

| File | Role | Autoload | Owner |
|------|------|----------|-------|
| `godot_project/scripts/core/GameController.gd` | Song lifecycle coordinator | Yes | Agent 01 |
| `godot_project/scripts/core/GameStateManager.gd` | Gameplay state machine | Yes | Agent 01 |
| `godot_project/scripts/core/GameConfig.gd` | Constants / lane normalization | Yes | Agent 01 |
| `godot_project/scripts/AudioSync.gd` | Authoritative hardware audio clock | Yes | Agent 03 |
| `godot_project/scripts/LaneManager.gd` | Viewport lanes + multi-touch | No (Node2D) | Agent 02 |
| `godot_project/scripts/NoteSpawner.gd` | Object-pool note renderer | No (Node2D) | Agent 02 |
| `godot_project/scripts/ScoreManager.gd` | Hit judgment + scoring | Yes | Agent 05 |
| `godot_project/scripts/ChartLoader.gd` | Chart IO + schema validation | Yes | Agent 03 |
| `godot_project/scripts/GameScene.gd` | Gameplay root scene; wires AudioPlayer | No | Agent 04 |

Autoloads registered in `project.godot`: GameConfig, GameStateManager, GameController, ChartLoader, AudioSync, ScoreManager. LaneManager and NoteSpawner are scene nodes, not autoloads.

## 2. Interface consistency

### 2.1 AudioSync — mixed accessor styles

AudioSync exposes both getter methods **and** public member variables:

- Getters: `get_playback_position_seconds()`, `get_raw_audio_time()`, `get_offset()`, `get_approach_time()`, `is_playing()`
- Public vars read directly by consumers: `adjusted_system_time`, `active_playback_flag`, `current_audio_time`, `audio_player_node`, `APPROACH_TIME` (const)

Consumers:
- `NoteSpawner._process` reads `AudioSync.active_playback_flag` (line 52), `AudioSync.adjusted_system_time` (line 55), `AudioSync.APPROACH_TIME` (line 71)
- `ScoreManager._process` / `process_action_input` read `AudioSync.adjusted_system_time` directly (lines 121, 208)

Finding: No functional defect, but the accessor style is inconsistent across the integration boundary. `get_approach_time()` is declared but never called; `get_playback_position_seconds()` is never called. Recommendation: consumers use getters exclusively, or AudioSync documents the public vars as the stable API. Low severity.

### 2.2 LaneManager — dead gameplay-state gate

`LaneManager._ready` connects `column_touch_down` **directly** to `ScoreManager.process_action_input` (line 30):

```gd
column_touch_down.connect(Callable(ScoreManager, "process_action_input"))
```

A separate handler `_on_column_touch_down` (line 98) gates on `GameStateManager.is_playing()`, but it is **never connected** to `column_touch_down`. The only runtime gate is `input_enabled`, which GameController never toggles on pause/resume.

Finding: Touches reach ScoreManager even during PAUSED / MAIN_MENU as long as `input_enabled` is true. The `is_playing` guard is dead code. This is a pause/resume reliability defect (see §4). Owner: Agent 02 (LaneManager) — connect `_on_column_touch_down` or gate `process_action_input` via GameStateManager.

### 2.3 GameConfig — redundant GAME_STATES mirror

`GameConfig.GAME_STATES` (lines 7–15) is a String dictionary duplicating `GameStateManager.GameState` enum values. It is not referenced by any audited file.

Finding: Harmless but redundant. No code depends on it. Recommend removal or document as legacy. Low severity.

### 2.4 Signal emission style

GameController declares signals (`signal song_loaded(song_id: String)`) but emits them by string name: `emit_signal("song_loaded", song_id)`. Functional in GDScript, but bypasses the typed declaration. Consistent across all GameController emissions. Low severity; no change required.

## 3. Initialization and timing race conditions

### R-1: NoteSpawner is never driven by GameController (gap in the init contract)

The documented init contract is:

```
GameController → ChartLoader → GameConfig → LaneManager → ScoreManager → NoteSpawner
```

`GameController.prepare_song()` loads the chart via ChartLoader and calls `ScoreManager.reset_scoring_matrix(current_chart)`. `GameController.start_song()` transitions to PLAYING and starts the audio pipeline. **However, `start_song()` never calls `NoteSpawner.start_spawning_sequence(chart)`.** NoteSpawner's `tracking_chart_timeline` stays empty, so no notes are ever spawned during gameplay regardless of chart timing.

Finding: Gameplay cannot produce notes. GameController must invoke `NoteSpawner.start_spawning_sequence(current_chart)` after ScoreManager reset (or own the ordering). Because GameController is an autoload and NoteSpawner is a scene node, this requires a scene reference (e.g. via GameScene) or a registry — see R-2. Owner: Agent 01 (GameController) + Agent 04 (GameScene wiring).

### R-2: AudioStreamPlayer assignment race

`GameScene._ready` calls `AudioSync.initialize_playback_channel($AudioPlayer)` (GameScene.gd line 7). `GameController.start_song()` calls `AudioSync.start_audio_pipeline()`, which `printerr`s and returns if `audio_player_node == null`, but GameController still transitions to PLAYING and emits `song_started`.

Finding: If `start_song()` is invoked before GameScene is ready (or `$AudioPlayer` is missing), audio never starts but the game reports PLAYING. Silent failure with no recovery. Recommendation: `start_song()` should verify `AudioSync.is_playing()`-preconditions or defer until the AudioStreamPlayer is assigned; surface a failure signal. Owner: Agent 01 + Agent 04.

### R-3: Chart schema validation is upstream; NoteSpawner reads `noteTimeline` without a guard

`NoteSpawner.start_spawning_sequence` does `tracking_chart_timeline = chart_data["noteTimeline"]` with no type guard (noted in MVP02 report). ChartLoader validates schema, but if NoteSpawner is invoked with a non-ChartLoader payload it will crash. Owner: Agent 02. Low severity given current callers.

### R-4: ScoreManager O(n) full-timeline scan each `_process`

`ScoreManager._process` iterates the entire `reference_timeline` every frame to detect misses (lines 209–215). Acceptable for MVP chart sizes; not a race condition. Documented for awareness.

## 4. Pause/resume lifecycle reliability

### P-1: Pause does not pause audio (defect)

`GameController.pause_song()` transitions to PAUSED and emits `song_paused`, but:
- Does **not** call `AudioSync.stop_audio_pipeline()` or any pause API.
- Does **not** set `is_game_active = false`.
- Does **not** toggle `LaneManager.input_enabled`.

`AudioSync` has no `pause`/`unpause` API — only `start_audio_pipeline()` / `stop_audio_pipeline()`. AudioServer's `AudioStreamPlayer` itself is never paused.

Consequence: `AudioSync._process` keeps advancing `adjusted_system_time`; `NoteSpawner._process` (gated only on `active_playback_flag`) keeps spawning/moving notes; `ScoreManager._process` keeps registering misses. Pause is state-only — gameplay continues in the background. **This is the highest-severity defect in the review.**

### P-2: Resume does not resume audio (defect)

`GameController.resume_song()` requires `current_state == PAUSED`, transitions to PLAYING, but never restarts the audio pipeline. If audio had been stopped, resume is silent. There is no AudioSync resume API to call. Owner: Agent 01 (GameController) + Agent 03 (AudioSync must expose pause/resume).

### P-3: Touch input not gated during pause (defect)

`LaneManager.input_enabled` is never set false on pause / true on resume. Combined with the dead `_on_column_touch_down` gate (§2.2), `ScoreManager.process_action_input` is invoked for touches during PAUSED, potentially consuming notes/judgment while paused. Owner: Agent 01 (GameController toggles `input_enabled`) + Agent 02 (LaneManager exposes it — already does via `set_input_enabled`).

### P-4: complete/game_over/exit stop audio correctly

`complete_song()`, `game_over()`, `exit_to_menu()` all call `AudioSync.stop_audio_pipeline()` and reset `is_game_active = false`. These paths are consistent. pause/resume are the asymmetric outliers.

### P-5: State-machine transition validity

`GameStateManager.transition_to()` permits any state → any state (except no-op). No transition table enforces e.g. MAIN_MENU → PLAYING directly. No functional defect observed because GameController is the sole caller and sequences correctly, but nothing enforces it at the manager level. Low severity.

## 5. Unnecessary rebuilds

No unnecessary rebuilds found:

- `NoteSpawner` preallocates a 200-node `ColorRect` pool at `_ready` and reuses it; no nodes are instantiated during gameplay. This is the intended GC-free design — not a rebuild.
- `ScoreManager` reuses `resolved_flags` Dictionary and clears it on `reset_scoring_matrix`.
- `LaneManager` recalculates viewport metrics on `size_changed` only.
- `ChartLoader` validates + normalizes on each load (expected, on demand).
- `GameConfig.GAME_STATES` is redundant data, not a runtime rebuild.

Finding: All systems are already built for no-rebuild gameplay. No rewrite recommended.

## 6. Defect register

| ID | Severity | Defect | File(s) | Recommended owner |
|----|----------|--------|---------|-------------------|
| D-01 | High | Pause does not stop/pause audio; notes and miss detection keep running during PAUSED | GameController.gd, AudioSync.gd | Agent 01 + Agent 03 |
| D-02 | High | Resume does not restart audio pipeline; no pause/resume API on AudioSync | GameController.gd, AudioSync.gd | Agent 01 + Agent 03 |
| D-03 | High | GameController never calls NoteSpawner.start_spawning_sequence; no notes spawn | GameController.gd | Agent 01 + Agent 04 |
| D-04 | Medium | Silent failure if start_song() runs before AudioStreamPlayer assigned | GameController.gd, GameScene.gd, AudioSync.gd | Agent 01 + Agent 04 |
| D-05 | Medium | LaneManager `_on_column_touch_down` is_playing gate never connected; touches reach ScoreManager during pause | LaneManager.gd | Agent 02 |
| D-06 | Medium | Touch input (`input_enabled`) not toggled on pause/resume | GameController.gd, LaneManager.gd | Agent 01 + Agent 02 |
| D-07 | Low | Inconsistent AudioSync accessor style (getters vs public vars); unused getters | AudioSync.gd, NoteSpawner.gd, ScoreManager.gd | Agent 03 |
| D-08 | Low | GameConfig.GAME_STATES duplicates GameStateManager enum, unused | GameConfig.gd | Agent 01 |

## 7. Recommended corrective actions (no system rebuilds)

1. **AudioSync** (Agent 03): add `pause_audio_pipeline()` / `resume_audio_pipeline()` wrapping `AudioStreamNode.set_paused()` (or stop/start with position preservation). Keep existing start/stop unchanged.
2. **GameController** (Agent 01): `pause_song()` → pause audio, set `is_game_active = false`, set `LaneManager.input_enabled = false` (via scene reference). `resume_song()` → resume audio, set `is_game_active = true`, re-enable input. Guard `start_song()` against unassigned AudioStreamPlayer and surface failure via existing signals.
3. **GameController + GameScene** (Agent 01 + Agent 04): wire `NoteSpawner.start_spawning_sequence(current_chart)` into the start flow after ScoreManager reset, preserving the init contract order.
4. **LaneManager** (Agent 02): connect `_on_column_touch_down` to `column_touch_down` (replacing or supplementing the direct ScoreManager binding) so the `is_playing` gate is enforced.
5. **GameConfig** (Agent 01): remove unused `GAME_STATES` or document as legacy.
6. Do **not** rewrite NoteSpawner, ScoreManager, AudioSync clock, or LaneManager pool — they already satisfy the no-rebuild requirement.

## 8. Conclusion

The core lifecycle foundation (GameController, GameStateManager, GameConfig) is present and internally consistent, and no system requires rebuilding. However, pause/resume is not reliable (audio/notes keep running during pause), the NoteSpawner is never invoked by GameController, and there is an AudioStreamPlayer assignment race. These are coordination/wiring defects confined to the lifecycle seams, not flaws in the individual systems. Fixing D-01 through D-06 requires small additive changes across Agent 01 (GameController/GameConfig), Agent 02 (LaneManager), Agent 03 (AudioSync pause/resume), and Agent 04 (GameScene wiring) — no existing system rebuilds.

## Files owned by Agent 01 for this review

- `godot_project/scripts/core/GameController.gd`
- `godot_project/scripts/core/GameStateManager.gd`
- `godot_project/scripts/core/GameConfig.gd`
- `docs/architecture/MVP03_ARCHITECTURE_REVIEW.md` (this document)
