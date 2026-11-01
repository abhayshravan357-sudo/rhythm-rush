# SCENE ARCHITECTURE — PROJECT RHYTHM (MVP-01)

## Scope

Documents the Godot 4 scene/node architecture for the MVP-01 game lifecycle:
menu → song select → loading → gameplay → pause → results → game-over → menu.

Lane count is configurable: **4 lanes for MVP** (default), **6 lanes** supported as
a foundation fallback via `GameConfig.ALLOWED_LANE_COUNTS = [4, 6]`.

## Autoload architecture (project.godot [autoload])

All seven autoloads are registered and their script files exist:

| Autoload | Script | Responsibility |
|---|---|---|
| GameConfig | scripts/core/GameConfig.gd | Lane count normalization, game-state string map |
| GameStateManager | scripts/core/GameStateManager.gd | Game-state machine, transitions |
| GameController | scripts/core/GameController.gd | Song lifecycle, state transitions, signals |
| ChartLoader | scripts/ChartLoader.gd | JSON chart IO, validation, window slicing |
| AudioSync | scripts/AudioSync.gd | Hardware-clock audio timing |
| ScoreManager | scripts/ScoreManager.gd | Hit evaluation, combo, scoring |
| OffsetCalibration | scripts/OffsetCalibration.gd | Latency calibration, user:// persistence |

Verification: every autoload path in `project.godot` resolves to an existing file. No autoload is missing or dangling.

## Game-state machine

Owned by `GameStateManager` (autoload). States:

```text
MAIN_MENU -> SONG_SELECTION -> LOADING -> PLAYING
                              ^         |      |
                              |         v      v
                              |       PAUSED  RESULTS
                              |         |       |
                              +---------+       v
                                          GAME_OVER
                                              |
                                              v
                                          MAIN_MENU
```

- `MAIN_MENU` — entry; song catalog + calibrate + play.
- `SONG_SELECTION` — pick a song (not yet wired; deferred to Agent 04).
- `LOADING` — chart loaded via `GameController.prepare_song()`.
- `PLAYING` — active gameplay; audio pipeline running.
- `PAUSED` — gameplay paused; audio paused.
- `RESULTS` — song completed successfully; final score shown.
- `GAME_OVER` — song abandoned/failed mid-play; final score shown.
- `CALIBRATION` — latency calibration flow.

Transitions are emitted via `state_changed(from, to)`. Helpers: `is_playing()`,
`is_paused()`, `is_game_over()`, `reset_to_main_menu()`.

## Scene structure

### MainMenu.tscn (`res://scenes/MainMenu.tscn`)
Root: `Control`. Children: `Background`, `VBox` containing `TitleLabel`,
`ServerIPLabel`, `IPInput`, `SyncButton`, `SongListLabel`, `SongList`,
`HBox` (`PlayButton`, `CalibrateButton`), `StatusLabel`.
Attached script: `MenuNetworkSyncReceiver.gd` (song-catalog network sync).

State transitions are not yet wired into `GameStateManager`/`GameController`.
`PlayButton` → `GameController.prepare_song()` + `start_song()` is the intended
entry into `LOADING` → `PLAYING`. Wiring is scene-architecture work owned here
but deferred pending Agent 00 review of signal boundaries.

### GameScene.tscn (`res://scenes/GameScene.tscn`)
Root: `Node2D`. Children:
- `Background` (ColorRect)
- `LaneManager` (Node2D, `LaneManager.gd`) — viewport partitioning, 4-lane
  column layout derived from `GameConfig.DEFAULT_LANE_COUNT = 4`
- `LaneDividers` (Node2D)
- `JudgmentLine` (ColorRect) at 85% of viewport height
- `NoteSpawner` (Node2D, `NoteSpawner.gd`) — preallocated object pool of
  `ColorRect` notes; no runtime instantiation
- `AudioPlayer` (AudioStreamPlayer) — wired to `AudioSync` via
  `AudioSync.initialize_playback_channel()`
- `HUD` (CanvasLayer) — `ScoreLabel`, `ComboLabel`, `RatingLabel`, `PauseButton`

Lane layout: `column_width_step = screen_width / lane_count` (480px at 1920px
for 4 lanes). `fixed_judgment_y = screen_height * 0.85`. Responsive to
viewport resize via `size_changed`.

The root `GameScene` node has no attached script. Coordination between
`LaneManager`, `NoteSpawner`, `AudioSync`, `ScoreManager` and `GameController`
is delegated to Agent 02 (gameplay integration, scripts/gameplay/).

### CalibrationScene.tscn (`res://scenes/CalibrationScene.tscn`)
Root: `Control`. Children: `Background`, `VBox` containing title, instructions,
`BeatIndicator`/`BeatLabel`, `TapButton` (disabled until started),
`TapCountLabel`, `ResultLabel`, `HBox` (`StartButton`, `BackButton`).
No script attached; OffsetCalibration workflow not yet scene-wired (deferred).

## Data flow contract

1. Menu selects song → `GameController.prepare_song(song_id, chart_path)` loads
   chart via `ChartLoader`, resets `ScoreManager`, transitions to `LOADING`.
2. `GameController.start_song()` → `PLAYING`; `AudioSync.start_audio_pipeline()`
   begins playback; `NoteSpawner` spawns notes within the approach window.
3. Lane touch → `ScoreManager.process_action_input(lane)` evaluates hit vs
   `AudioSync.adjusted_system_time`; emits `alignment_processed`.
4. Song ends → `complete_song()` → `RESULTS` + `song_completed` signal.
   Mid-song failure → `game_over(score, combo, accuracy)` → `GAME_OVER`
   + `game_over` signal.
5. Pause/resume → `pause_song()` / `resume_song()` toggle `PLAYING` ↔ `PAUSED`.
6. Exit → `exit_to_menu()` → `MAIN_MENU`, clears chart/song state.

## Boundaries & ownership

- `godot_project/scripts/core/` and `godot_project/scenes/`: Agent 01 (this agent).
- `project.godot` (shared autoload manifest): Agent 00; changes require Chief
  Engineer approval. No changes made here in MVP-01.
- Gameplay input/hit wiring inside `GameScene`: Agent 02 (scripts/gameplay/).
- UI screens & transitions (Agent 04), persistence (Agent 05), audio sync
  contract (Agent 03) are separate ownership domains.

## MVP-01 acceptance (this document)

- [x] Game-state machine defined: menu/gameplay/pause/results/game-over/calibration
- [x] Scene structure documented; GameScene composed for 4-lane MVP
- [x] Autoload architecture intact; all 7 autoloads verified present
- [x] Lane count configurable: default 4 (MVP), 6 supported (foundation)
- [ ] Changes reviewed by Agent 00 before integration
