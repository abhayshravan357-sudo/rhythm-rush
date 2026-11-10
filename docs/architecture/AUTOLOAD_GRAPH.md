# AUTOLOAD DEPENDENCY GRAPH — PROJECT RHYTHM (Agent 01 — Architecture)

**Date:** 2026-11-04  
**Owner:** Agent 01 — Game Architecture Engineer  
**Branch:** agent/project-rhythm-architecture / c-016-autoload-graph  
**Milestone:** MVP-01a / Batch 2 + Tasks C-026..C-040

## 1. Overview

This document maps the autoload singleton architecture in `godot_project/scripts/` and `godot_project/scripts/core/`, their initialization order, interface contracts, dependency relationships, and identified integration risks. It is intended to help contributors understand system boundaries and avoid circular dependencies or incorrect initialization order.

## 2. Autoload Registry

All seven core autoloads are registered in `project.godot:[autoload]` and their script files exist on disk.

| Autoload Name | Script Path | Registers As | Responsibility |
|---------------|-------------|--------------|----------------|
| GameConfig | `godot_project/scripts/core/GameConfig.gd` | GameConfig | Lane count config (`DEFAULT_LANE_COUNT=4`, `ALLOWED_LANE_COUNTS=[4,6]`), `GAME_STATES` map, `normalize_lane_count()`, `is_supported_lane_count()` |
| GameStateManager | `godot_project/scripts/core/GameStateManager.gd` | GameStateManager | Game lifecycle state machine (MAIN_MENU → SONG_SELECTION → LOADING → PLAYING → PAUSED → RESULTS → GAME_OVER → CALIBRATION), `transition_to()`, state queries |
| GameController | `godot_project/scripts/core/GameController.gd` | GameController | Session lifecycle: `prepare_song`, `start_song`, `pause_song`, `resume_song`, `complete_song`, `game_over`, `exit_to_menu` |
| ChartLoader | `godot_project/scripts/ChartLoader.gd` | ChartLoader | JSON chart loading, validation, lane-count normalization, note timeline access |
| AudioSync | `godot_project/scripts/AudioSync.gd` | AudioSync | Authoritative audio-clock timing (`get_playback_position` + `get_time_since_last_mix`), pause/resume, calibration offset, drift analysis |
| ScoreManager | `godot_project/scripts/ScoreManager.gd` | ScoreManager | Hit precision evaluation, combo tracking, score multiplier, accuracy, grade calculation |
| OffsetCalibration | `godot_project/scripts/OffsetCalibration.gd` | OffsetCalibration | Latency calibration, user:// persistence of user offset |
| SceneTransitionManager | `godot_project/scripts/core/SceneTransitionManager.gd` | SceneTransitionManager | Centralized scene loading, named scene registry, `change_scene_to()` |
| GameStatePersistence | `godot_project/scripts/core/GameStatePersistence.gd` | GameStatePersistence | `user://` JSON game-state persistence with checksum validation |

### Registered but not yet documented in interface contracts
| Autoload Name | Script Path | Registers As | Responsibility |
|---------------|-------------|--------------|----------------|
| AudioFeedback | `godot_project/scripts/systems/AudioFeedback.gd` | AudioFeedback | Audio feedback / SFX playback |
| SettingsManager | `godot_project/scripts/systems/SettingsManager.gd` | SettingsManager | User settings management |

### Not registered (script files exist on disk but not yet in project.godot:[autoload])
- **SceneTransitionManager** — `godot_project/scripts/core/SceneTransitionManager.gd` exists; registration requires Agent 00 coordination
- **GameStatePersistence** — `godot_project/scripts/core/GameStatePersistence.gd` exists; registration requires Agent 00 coordination
- **SaveManager** — not in project.godot autoload section
- **SongUnlockManager** — not in project.godot autoload section

## 3. Initialization Order (Dependency Chain)

The following order must be respected at application startup:

```
1. GameConfig           (no dependencies — pure constants)
2. GameStateManager     (no dependencies — pure state machine)
3. ChartLoader          (depends on GameConfig for lane count normalization)
4. AudioSync            (depends on GameConfig for approach time / judgment windows)
5. ScoreManager         (depends on GameConfig for scoring constants, AudioSync for timing windows)
6. GameController       (depends on ChartLoader, ScoreManager, AudioSync, GameStateManager)
7. SceneTransitionManager (no external dependencies — pure scene utility)
8. GameStatePersistence (depends on user:// file I/O only — independent)
```

Additional autoloads (no gameplay ordering constraint):
- OffsetCalibration — loads user:// offset in `_ready()`, independent
- AudioFeedback — independent SFX system
- SettingsManager — independent settings system

### Rationale

- **GameConfig** and **GameStateManager** are pure data/state with no external dependencies — they initialize first.
- **ChartLoader** needs GameConfig to normalize lane counts during chart validation (`validate_chart_payload` calls `GameConfig.normalize_lane_count`).
- **AudioSync** needs GameConfig for timing constants and reads user:// offset in `_ready()`.
- **ScoreManager** reads `AudioSync.adjusted_system_time` and `AudioSync.get_judgment_window_*()` during hit evaluation — AudioSync must be ready first.
- **GameController** is the orchestrator — it calls `ChartLoader.load_chart()`, `ScoreManager.reset_scoring_matrix()`, `AudioSync.start_audio_pipeline()`, and `GameStateManager.transition_to()`.
- **SceneTransitionManager** is a pure scene utility with no gameplay dependencies — it wraps `load()` and `get_tree().change_scene_to_packed()`.
- **GameStatePersistence** performs `user://` file I/O only — independent of all other autoloads.

## 4. Interface Contracts

### GameConfig → All consumers
- `DEFAULT_LANE_COUNT: int = 4`, `ALLOWED_LANE_COUNTS: Array[int] = [4, 6]`
- `GAME_STATES: Dictionary` — state name map
- `normalize_lane_count(count: int) -> int`
- `is_supported_lane_count(count: int) -> bool`

### GameStateManager → GameController, GameScene
- `transition_to(state: GameState) -> void` — emits `state_changed(from, to)`
- `is_playing() -> bool`, `is_paused() -> bool`, `is_game_over() -> bool`
- `reset_to_main_menu() -> void`
- `current_state`, `previous_state` properties

### ChartLoader → GameController, ScoreManager
- `load_chart(file_path: String) -> Dictionary` — loads and validates JSON chart
- `get_notes_in_window(time_start, time_end) -> Array`
- `get_metadata() -> Dictionary`

### AudioSync → ScoreManager, NoteSpawner, GameScene, GameController
- `adjusted_system_time: float` — authoritative playback position
- `start_audio_pipeline()`, `stop_audio_pipeline()`, `pause_audio_pipeline()` — playback control
- `get_judgment_window_perfect() -> float`, `get_judgment_window_good() -> float`
- `APPROACH_TIME: float = 1.5` — note approach window
- `song_completed` signal — emitted when playback reaches end

### ScoreManager → GameController, GameScene, LaneManager
- `reset_scoring_matrix(chart_payload: Dictionary) -> void`
- `process_action_input(target_lane: int) -> void` — evaluate a hit on a lane
- `get_score() -> int`, `get_combo() -> int`, `get_max_combo() -> int`, `get_accuracy() -> float`, `get_grade() -> String`
- `alignment_processed(rating, combo, accuracy)` signal — per-hit judgment
- `sequence_tracking_concluded(final_score, max_combo, accuracy, grade)` signal — end of sequence

### GameController → All consumers (orchestrator)
- `prepare_song(song_id, chart_path) -> bool`
- `start_song()`, `pause_song()`, `resume_song()`, `complete_song()`, `game_over(...)`, `exit_to_menu()`
- `song_loaded`, `song_started`, `song_paused`, `song_completed`, `game_over_triggered` signals

### SceneTransitionManager → All consumers
- `load_scene(path: String) -> PackedScene` — loads a PackedScene, returns null on failure
- `change_scene(path: String) -> bool` — loads and changes scene in one call
- `change_scene_to(scene_name: String) -> bool` — changes by registered logical name
- `register_scene(name: String, path: String) -> void` — registers a named scene path
- `get_scene_path(name: String) -> String` — resolves a registered path
- `scene_loaded(path)` signal — emitted on successful load
- `scene_load_failed(path, reason)` signal — emitted on load/change failure

### GameStatePersistence → All consumers
- `save_game_state(data_dict: Dictionary) -> bool` — persists with checksum to user://
- `load_game_state() -> Dictionary` — loads and validates; returns {} on failure
- `validate_save_data(payload: Dictionary) -> bool` — checks structure, version, checksum
- `clear_save_data() -> bool` — deletes the persisted save file
- `state_saved(path)` signal — emitted after successful save
- `state_load_failed(reason)` signal — emitted on load/validation failure

## 5. Dependency Rules

1. **No circular dependencies.** Autoloads must not reference each other in a circular manner. Verified: none found.
2. **GameConfig and GameStateManager are leaf nodes** — they depend on nothing.
3. **GameController is the root orchestrator** — depends on all gameplay systems; nothing depends on it except UI scenes calling its signals.
4. **AudioSync is the authoritative time source** — all timing-dependent systems read `adjusted_system_time`, never frame delta.
5. **LaneManager is a scene Node2D, not an autoload** — it reads `GameConfig` and calls `ScoreManager.process_action_input` via signal.
6. **SceneTransitionManager is a leaf utility** — depends on nothing except Godot's `load()` and SceneTree; safe to call from any UI script.
7. **GameStatePersistence is a leaf utility** — depends only on `user://` file I/O and `Time`; safe to call from any system.

## 6. Integration Risks

### R-01: LaneManager bypasses debounce and state gating (HIGH)
LaneManager._ready() connects `column_touch_down` directly to `ScoreManager.process_action_input` (line 53), bypassing the debounce logic and `GameStateManager.is_playing()` gate defined in `_on_column_touch_down` (lines 259-268). `_on_column_touch_down` is defined but never connected to any signal, so its debounce and state checks never execute. Rapid same-lane taps could register multiple judgments; input could be processed outside PLAYING state.
**Recommendation:** Connect `_on_column_touch_down` to `column_touch_down` instead of connecting `ScoreManager.process_action_input` directly, or add `is_playing()` + debounce checks at the signal connection point.

### R-02: GameController calls PlayerProfile without nil guards (MEDIUM)
`GameController.complete_song()` calls `PlayerProfile.get_high_score()`, `PlayerProfile.record_play()`, `PlayerProfile.add_xp()`, `PlayerProfile.save_profile()` directly. PlayerProfile is an autoload — if its script fails to load or is unregistered, `complete_song()` will crash with a null-reference error.
**Recommendation:** Add `if PlayerProfile == null:` guards or wrap PlayerProfile calls in a safe helper.

### R-03: GameScene and GameController both start AudioSync pipeline (LOW)
`GameScene._bootstrap_gameplay()` calls `AudioSync.start_audio_pipeline()` directly, and `GameController.start_song()` also calls it. If both entry paths are exercised, `start_audio_pipeline()` is called twice. AudioSync handles this gracefully (calling `play()` on an already-playing `AudioStreamPlayer` is a no-op in Godot), but it couples scene bootstrap to controller lifecycle.
**Recommendation:** Route all audio pipeline starts through `GameController.start_song()` only; GameScene should call `GameController.start_song()` rather than `AudioSync.start_audio_pipeline()` directly.

### R-04: ScoreManager reads AudioSync state without null check (LOW)
`ScoreManager.process_action_input()` and `_process()` read `AudioSync.adjusted_system_time` and call `AudioSync.get_judgment_window_*()` directly. If AudioSync fails to initialize, these calls will error.
**Recommendation:** Add `if AudioSync == null: return` guards at the top of input-processing paths.

## 7. Circular Dependency Check

Verified — no circular dependencies exist:

```
GameConfig              → (none)
GameStateManager        → (none)
ChartLoader             → GameConfig
AudioSync               → GameConfig
ScoreManager            → GameConfig, AudioSync
GameController          → ChartLoader, ScoreManager, AudioSync, GameStateManager
SceneTransitionManager  → (none)
GameStatePersistence    → (none)
LaneManager             → GameConfig, ScoreManager (scene node, not autoload)
NoteSpawner             → AudioSync, LaneManager (scene node, not autoload)
```

Dependency graph is acyclic. GameConfig → GameStateManager → ChartLoader → AudioSync → ScoreManager → GameController is a valid linear chain with no back-edges. SceneTransitionManager and GameStatePersistence are leaves with no incoming gameplay dependencies.

## 8. Adding a New Autoload

1. Create the script in `godot_project/scripts/` or an appropriate subdirectory.
2. Register it as an autoload in `project.godot` (requires Agent 00 coordination).
3. Document its dependencies in this document.
4. Verify no circular dependency is introduced.
5. Add unit tests in `tests/unit/` if the autoload contains logic.
