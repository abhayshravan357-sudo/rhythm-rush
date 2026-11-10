# UI HUB ARCHITECTURE REVIEW — PROJECT RHYTHM (Agent 01 — Architecture)

**Date:** 2026-11-04  
**Owner:** Agent 01 — Game Architecture Engineer  
**Branch:** agent/project-rhythm-architecture / c-016-autoload-graph  
**Milestone:** MVP-01a / Batch 2 — Agent 04 UI Hub review

## 1. Overview

This document reviews the existing scene architecture, UI scripts, autoload contracts, navigation patterns, and the Game Design Document (GDD) screen requirements to support Agent 04's planned "Four-Lane Interactive Game Hub" UI implementation. It identifies architectural risks and recommends how the UI hub should connect to `GameController`/`GameStateManager` without bypassing the existing architecture.

## 2. Existing Scene Architecture

All scenes are top-level `Control`/`Node2D` roots with an attached UI controller script. Each scene loads and transitions independently via `get_tree().change_scene_to_packed()` / `change_scene_to_file()`.

| Scene | Path | Root Type | UI Script | Script Attachment |
|-------|------|-----------|-----------|-------------------|
| Main Menu | `res://scenes/MainMenu.tscn` | `Control` | `MainMenuUI.gd` | Child node `MenuUI` (root script = `MenuNetworkSyncReceiver.gd`) |
| Song Selection | `res://scenes/SongSelection.tscn` | `Control` | `SongSelectionUI.gd` | Directly on root |
| Calibration | `res://scenes/CalibrationScene.tscn` | `Control` | `CalibrationUI.gd` | Directly on root (`extends Control`) |
| Gameplay | `res://scenes/GameScene.tscn` | `Node2D` | `GameScene.gd` | Directly on root |
| Results | `res://scenes/Results.tscn` | `Control` | `ResultsUI.gd` | Directly on root (`extends Control`) |
| Settings | `res://scenes/Settings.tscn` | `Control` | `SettingsUI.gd` | Directly on root (implied) |
| Profile | `res://scenes/Profile.tscn` | `Control` | `ProfileUI.gd` | Directly on root (implied) |

### UI controller scripts reviewed

| Script | Path | Dependencies (autoloads / systems) |
|--------|------|-----------------------------------|
| MainMenuUI | `res://scripts/ui/MainMenuUI.gd` | GameStateManager, GameController, ChartLoader, ResponsiveLayout |
| SongSelectionUI | `res://scripts/ui/SongSelectionUI.gd` | GameStateManager, GameController, ChartLoader, PlayerProfile, GameConfig, ResponsiveLayout |
| CalibrationUI | `res://scripts/ui/CalibrationUI.gd` | OffsetCalibration, ResponsiveLayout |
| ResultsUI | `res://scripts/ui/ResultsUI.gd` | GameController, PlayerProfile, ResponsiveLayout |
| SettingsUI | `res://scripts/ui/SettingsUI.gd` | SettingsManager, ResponsiveLayout |
| ProfileUI | `res://scripts/ui/ProfileUI.gd` | PlayerProfile, ResponsiveLayout |
| GameScene | `res://scripts/GameScene.gd` | AudioSync, ScoreManager, GameStateManager, GameController, LaneManager, NoteSpawner |

### Shared UI utilities

| Script | Path | Responsibility |
|--------|------|----------------|
| ResponsiveLayout | `res://scripts/ui/ResponsiveLayout.gd` | Viewport-aware centered panel sizing (`RefCounted`, no game deps) |
| AtmosphereBackground | `res://scripts/ui/AtmosphereBackground.gd` | Ambient glow drawn on `ColorRect` (`mouse_filter = IGNORE`) |

## 3. Existing Autoloads (verified in project.godot:[autoload])

| Autoload | Script Path | Registers As |
|----------|-------------|--------------|
| GameConfig | `res://scripts/core/GameConfig.gd` | GameConfig |
| GameStateManager | `res://scripts/core/GameStateManager.gd` | GameStateManager |
| GameController | `res://scripts/core/GameController.gd` | GameController |
| ChartLoader | `res://scripts/ChartLoader.gd` | ChartLoader |
| AudioSync | `res://scripts/AudioSync.gd` | AudioSync |
| ScoreManager | `res://scripts/ScoreManager.gd` | ScoreManager |
| AudioFeedback | `res://scripts/systems/AudioFeedback.gd` | AudioFeedback |
| OffsetCalibration | `res://scripts/OffsetCalibration.gd` | OffsetCalibration |
| PlayerProfile | `res://scripts/systems/PlayerProfile.gd` | PlayerProfile |
| SettingsManager | `res://scripts/systems/SettingsManager.gd` | SettingsManager |

### Autoloads referenced in AUTOLOAD_GRAPH.md but NOT registered
- **SceneLoader** — `res://scripts/core/SceneLoader.gd` missing from disk; not in project.godot
- **SaveManager** — not in project.godot autoload section
- **SongUnlockManager** — not in project.godot autoload section

## 4. Navigation Architecture & Scene Transition Patterns

### Current transition pattern (used by MainMenuUI, SongSelectionUI)

```
1. GameStateManager.transition_to(<target_state>)
2. get_tree().change_scene_to_packed(load(SCENE_PATH))
```

### Variations observed

| Script | Pattern | Notes |
|--------|---------|-------|
| MainMenuUI.go_to_song_selection | transition_to(SONG_SELECTION) + change_scene_to_packed | Consistent |
| MainMenuUI.go_to_calibration | transition_to(CALIBRATION) + change_scene_to_packed | Consistent |
| MainMenuUI.go_to_gameplay | GameController.prepare_song() + change_scene_to_packed | Routes through GameController |
| MainMenuUI._on_settings_pressed | change_scene_to_file(SCENE_SETTINGS) directly | No state transition |
| MainMenuUI._on_profile_pressed | change_scene_to_file(SCENE_PROFILE) directly | No state transition |
| SongSelectionUI._on_back_pressed | transition_to(MAIN_MENU) + change_scene_to_packed | Consistent |
| SongSelectionUI.go_to_gameplay | GameController.prepare_song() + change_scene_to_packed | Routes through GameController |
| CalibrationUI._on_back_pressed | change_scene_to_file("res://scenes/Settings.tscn") | Bypasses GameStateManager; goes to Settings, not Main Menu |
| ResultsUI._on_menu_pressed | GameController.exit_to_menu() + change_scene_to_file | Routes through GameController |
| ResultsUI._on_song_library_pressed | GameController.exit_to_menu() + transition_to(SONG_SELECTION) + change_scene_to_file | Routes through GameController |
| ResultsUI._on_retry_pressed | GameController.prepare_song() + change_scene_to_file | Routes through GameController |
| GameScene._on_return_to_menu_pressed | GameController.exit_to_menu() + change_scene_to_packed | Routes through GameController |

### Inconsistencies

1. **MainMenu root script conflict:** `MainMenu.tscn` root script is `MenuNetworkSyncReceiver.gd`, but `MainMenuUI.gd` is a separate child node (`MenuUI`) that reaches into the parent via `get_parent().get_node(...)` to wire buttons. Fragile if scene node names change.
2. **No state transition on Settings/Profile/Exit:** Direct `change_scene_to_file` without `GameStateManager.transition_to` leaves the state machine out of sync with the actual scene.
3. **Calibration back goes to Settings, not Main Menu:** `CalibrationUI._on_back_pressed` loads `Settings.tscn` directly with no state change — inconsistent with the "back returns to main menu" pattern used elsewhere.
4. **Direct `change_scene_to_file` vs `change_scene_to_packed`:** Mixed usage across scripts; no centralized scene-loading utility (SceneLoader is referenced in AUTOLOAD_GRAPH.md but does not exist).

## 5. GDD Navigation / UI Requirements

From `docs/game-design/GAME_DESIGN_DOCUMENT.md`, Section 11 (Screens):

1. Splash screen
2. Main menu (logo, play, song library, modes, daily challenges, profile, settings, rewards, progress)
3. Song selection (catalogue, title/artist/genre/difficulty/duration, preview, locked/unlocked, search/filter)
4. Song details
5. Gameplay (4 lanes, HUD: score, combo, rating, pause)
6. Pause menu
7. Results (score, combo, accuracy, grade, restart)
8. Game modes
9. Profile
10. Settings (volume, latency calibration, screen)

### GDD Section 14 (MVP scope, Wave 3)
- Main menu, song selection, one playable song, four-lane gameplay, music sync, touch detection, scoring+combo, game-over screen, results screen, restart, Android APK.

The GDD implies a **central navigation surface** (main menu with play, song library, modes, profile, settings) — consistent with a "Game Hub" concept where multiple screens branch from a common navigation root.

## 6. Integration Risks

### R-UI-01: Scene transitions bypass GameStateManager (MEDIUM)
Several UI handlers call `change_scene_to_file()` directly without `GameStateManager.transition_to()`:
- `MainMenuUI._on_settings_pressed` → Settings
- `MainMenuUI._on_profile_pressed` → Profile
- `CalibrationUI._on_back_pressed` → Settings (wrong target too)

**Risk:** The state machine drifts out of sync with the visible scene. Systems keyed on `GameStateManager.is_playing()` / `is_paused()` (e.g., `LaneManager._on_column_touch_down`) may misbehave if the scene is Settings/Profile but state still reads PLAYING.

**Recommendation:** Every scene change should pair `GameStateManager.transition_to(<state>)` with `change_scene_to_packed/file()`. Add a helper on GameController or a thin navigation wrapper so UI scripts don't duplicate the pair.

### R-UI-02: No central scene loader / navigation hub (MEDIUM)
Scene paths are hardcoded string literals duplicated across `MainMenuUI.gd`, `SongSelectionUI.gd`, `ResultsUI.gd`, `SettingsUI.gd`. `SceneLoader` is referenced in `AUTOLOAD_GRAPH.md` but the script `res://scripts/core/SceneLoader.gd` does not exist on disk and is not registered in `project.godot`.

**Risk:** Scene path refactors require editing multiple UI scripts; missed updates cause silent load failures. Agent 04's Game Hub would likely duplicate this pattern.

**Recommendation:** Implement `SceneLoader` autoload (per AUTOLOAD_GRAPH.md) with `load_scene(path)` / `change_scene(path)` methods, register it in `project.godot`, and route all UI scene transitions through it. Agent 04's Game Hub should use SceneLoader rather than inline `get_tree().change_scene_to_*`.

### R-UI-03: MainMenu root script is MenuNetworkSyncReceiver, not MainMenuUI (MEDIUM)
`MainMenu.tscn` root has `script = ExtResource("1_recv")` (`MenuNetworkSyncReceiver.gd`), while `MainMenuUI.gd` lives on a child `MenuUI` Node and reaches buttons via `get_parent().get_node("VBox/PlayButton")`. `MainMenuUI._ready` assumes specific child node paths.

**Risk:** Fragile coupling to scene node names/paths. If Agent 04 restructures MainMenu into a Game Hub, `MainMenuUI.gd` will break. The root script (`MenuNetworkSyncReceiver`) handles network catalog sync; `MainMenuUI` handles local UI — two concerns on one scene root is a separation-of-concerns issue.

**Recommendation:** For the Game Hub, use a clean root-attached UI controller (like `SongSelectionUI.gd`/`CalibrationUI.gd` pattern) rather than a child-node script reaching into the parent. Keep `MenuNetworkSyncReceiver` on a separate network node if needed.

### R-UI-04: PlayerProfile called without nil guards in UI scripts (MEDIUM)
`SongSelectionUI._on_song_selected` calls `PlayerProfile.get_high_score(...)`; `ResultsUI._ready` calls `PlayerProfile.get_high_score(...)`; `ProfileUI._ready` calls `PlayerProfile.get_profile()` and multiple getters. `PlayerProfile` is an autoload — if it fails to load, these calls crash with null-reference errors.

**Risk:** Same class of risk as R-02 in AUTOLOAD_GRAPH.md (`GameController.complete_song` calls PlayerProfile without guards). UI scripts compound it.

**Recommendation:** Add `if PlayerProfile == null:` guards at the top of UI `_ready`/input handlers that call PlayerProfile, or wrap in a safe helper. Coordinate with Agent 00/05 on PlayerProfile initialization guarantees.

### R-UI-05: Calibration back navigation targets wrong scene (LOW)
`CalibrationUI._on_back_pressed` loads `Settings.tscn` directly. Per GDD and the pattern used elsewhere, back from calibration should return to Main Menu (or Settings if launched from Settings). Currently it hardcodes Settings with no state transition.

**Recommendation:** Route calibration back through `GameStateManager.transition_to(MAIN_MENU)` + load `MainMenu.tscn`, or accept a `return_scene` parameter.

### R-UI-06: GameScene and GameController both start AudioSync pipeline (LOW — cross-cutting)
`GameScene._bootstrap_gameplay()` calls `AudioSync.start_audio_pipeline()` directly (line 94), and `GameController.start_song()` also calls it. If both paths fire, `start_audio_pipeline()` runs twice. Godot tolerates `play()` on an already-playing `AudioStreamPlayer`, but it couples scene bootstrap to controller lifecycle.

**Recommendation:** Route all audio pipeline starts through `GameController.start_song()` only; `GameScene._bootstrap_gameplay` should call `GameController.start_song()` rather than `AudioSync.start_audio_pipeline()` directly. Agent 04's Game Hub should never call `AudioSync.start_audio_pipeline()` — always go through `GameController`.

### R-UI-07: ScoreManager / AudioSync read without null guards in UI-adjacent code (LOW)
`SongSelectionUI._on_song_selected` calls `ChartLoader.load_chart()` directly (read-only metadata) — acceptable but duplicates chart-loading logic that `GameController.prepare_song` also performs. `ResultsUI._ready` reads `GameController.last_result` without checking `GameController` availability.

**Recommendation:** UI scripts should request data via `GameController` properties/methods rather than calling `ChartLoader`/`AudioSync`/`ScoreManager` directly where `GameController` already owns the flow. Add nil guards where autoloads are read directly.

## 7. Circular Dependency Check

No circular dependencies exist between autoloads and UI scripts:

```
GameConfig        → (none)
GameStateManager  → (none)
ChartLoader       → GameConfig
AudioSync         → GameConfig
ScoreManager      → GameConfig, AudioSync
GameController    → ChartLoader, ScoreManager, AudioSync, GameStateManager
PlayerProfile     → SaveManager (not registered), SettingsManager
SettingsManager   → (none)
UI scripts        → GameStateManager, GameController, ChartLoader, AudioSync, ScoreManager, PlayerProfile, SettingsManager, OffsetCalibration (all read-only autoload access)
```

UI scripts are leaves — they read autoloads but no autoload reads a UI script. Agent 04's Game Hub should follow the same leaf pattern: read autoloads, never be read by them.

## 8. Recommended Integration Approach for Agent 04's Game Hub

### Do (align with existing architecture)
1. **Route gameplay entry through `GameController.prepare_song()` + `GameController.start_song()`**, never call `AudioSync.start_audio_pipeline()` or `NoteSpawner.start_spawning_sequence()` directly from the hub.
2. **Pair every scene change with `GameStateManager.transition_to()`** before `change_scene_to_packed/file()`.
3. **Read-only autoload access only:** `GameConfig.DEFAULT_LANE_COUNT`, `GameStateManager.is_playing()`, `ScoreManager.get_score()`, `PlayerProfile.get_high_score()` — all fine.
4. **Use SceneLoader** (once implemented/registered) for scene transitions instead of inline `get_tree().change_scene_to_*`.
5. **Attach the hub's UI controller directly to the hub scene root** (like `SongSelectionUI.gd`/`CalibrationUI.gd`), not as a child node reaching into the parent.
6. **Respect 4-lane MVP:** Use `GameConfig.DEFAULT_LANE_COUNT = 4`; `normalize_lane_count()` for any lane-count input.

### Do Not (would bypass existing architecture)
1. Do **not** call `AudioSync.start_audio_pipeline()` / `stop_audio_pipeline()` directly from the hub — go through `GameController`.
2. Do **not** call `NoteSpawner.start_spawning_sequence()` directly — that's GameScene's job after `GameController.start_song()`.
3. Do **not** bypass `GameStateManager` for navigation state (e.g., direct scene change without `transition_to`).
4. Do **not** create a second, parallel state machine in the hub — `GameStateManager` is the single source of truth.
5. Do **not** modify `GameController`, `GameStateManager`, or `GameConfig` — those are Agent 01's ownership; coordinate changes via Agent 00.

### Suggested hub flow (main menu → song selection → gameplay)

```
Hub/Main Menu (GameStateManager.MAIN_MENU)
  ├─ Play → GameController.prepare_song() → LOADING → GameScene (PLAYING)
  ├─ Song Library → GameStateManager.transition_to(SONG_SELECTION) → SongSelection.tscn
  ├─ Settings → GameStateManager.transition_to(SETTINGS-ish) → Settings.tscn
  ├─ Profile → GameStateManager.transition_to(...) → Profile.tscn
  └─ Calibrate → GameStateManager.transition_to(CALIBRATION) → CalibrationScene.tscn
```

## 9. Deliverable Status

- `docs/architecture/AUTOLOAD_GRAPH.md` — already exists (commit `99907cc`); updated separately with risk analysis.
- `docs/architecture/UI_HUB_ARCHITECTURE.md` — **this document** (new file, created in this review).

## 10. Files Changed

- Created: `docs/architecture/UI_HUB_ARCHITECTURE.md`
