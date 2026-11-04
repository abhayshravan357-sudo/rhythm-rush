# GODOT RUNTIME VALIDATION PLAN — HEXARHYTHM

**Milestone:** Environment Setup & Runtime Readiness  
**Target Engine:** Godot 4.3  
**Execution Mode:** Godot Headless Engine Execution (`godot --headless`)  
**Test Suite Script:** `godot_project/scripts/tests/runtime_smoke_test.gd`  
**Test Scene:** `godot_project/scenes/RuntimeSmokeTest.tscn`

---

## 1. Objectives

1. Validate that the Godot 4.3 engine imports and compiles all project scripts, resources, shaders, and scenes without parse errors or fatal cyclic dependencies.
2. Verify that all autoload singletons (`GameConfig`, `GameStateManager`, `GameController`, `ChartLoader`, `AudioSync`, `ScoreManager`, `PlayerProfile`) initialize in their proper order.
3. Validate the complete lifecycle of rhythm gameplay under real engine execution:
   - Scene instantiation (`MainMenu`, `SongSelection`, `GameScene`).
   - Chart deserialization and schema validation.
   - Hardware audio channel initialization.
   - Object pooling and note spawning.
   - Multi-touch and simulated pointer input routing.
   - Hit judgment, scoring, combo tracking, and accuracy calculation.
   - Pause and resume timing stability.
   - Song completion and results calculation.
   - Retry sequence and clean return to main menu.

---

## 2. 26-Step Validation Sequence

| Step | Validation Phase | Method & Verification Assertion | Expected Result |
|:----:|:-----------------|:--------------------------------|:----------------|
| **01** | Engine Launch | Run `godot --version` | Godot 4.3 stable launches and outputs version |
| **02** | Project Import | Launch engine with `--path godot_project` | Project directory recognized by Godot Engine |
| **03** | Asset Import | Verify `.godot/imported/` generation | Assets (audio, data, scenes) compiled to engine cache |
| **04** | Parser & Resource Check | Headless editor scan (`--editor --quit`) | 0 script compile errors, 0 cyclic autoload conflicts |
| **05** | Autoload Singletons | Inspect `/root` tree for singletons | All 7 singletons instantiated and non-null |
| **06** | MainMenu Scene | Instantiate `res://scenes/MainMenu.tscn` | Node hierarchy loads cleanly into active tree |
| **07** | Play Button | Locate `$VBox/PlayButton` on MainMenu | Button exists with valid text and event binding |
| **08** | Song Library Transition | Locate `$VBox/SongLibraryButton` | Button exists and `SongSelection.tscn` is loadable |
| **09** | Chart Loading | Call `ChartLoader.load_chart()` | Valid JSON parsed with `metaData` and `noteTimeline` |
| **10** | Audio Loading | Load `res://assets/audio/example_track.ogg` | AudioStream resource loads as valid OggVorbis stream |
| **11** | GameController Init | Call `GameController.prepare_song()` | Sets `current_song_id`, loads chart, sets `LOADING` state |
| **12** | GameScene Execution | Instantiate `res://scenes/GameScene.tscn` | Gameplay scene tree instantiates in active viewport |
| **13** | Lanes & Judgment Line | Inspect `LaneManager` and `JudgmentLine` | 4 lanes configured; judgment line positioned at `y=918.0` |
| **14** | Note Object Pool | Inspect `NoteSpawner.preallocated_node_pool` | Exactly 200 `ColorRect` visual tiles pre-allocated |
| **15** | Touch / Input Handling | Inject `InputEventScreenTouch` at `x=240` | Resolved to Lane 0; emits `column_touch_down` |
| **16** | Hit & Miss Judgment | Invoke `ScoreManager.process_action_input(0)` | Hit precision evaluated; updates judgment counters |
| **17** | Scoring & Accuracy | Inspect ScoreManager counters | Score, combo, accuracy, and grade computed correctly |
| **18** | Gameplay Pause | Call `GameController.pause_song()` | Freezes audio clock; state transitions to `PAUSED` |
| **19** | Gameplay Resume | Call `GameController.resume_song()` | Restores audio clock; state returns to `PLAYING` |
| **20** | Song Completion | Call `GameController.complete_song()` | Deactivates audio pipeline; state transitions to `RESULTS` |
| **21** | Results Presentation | Inspect final scores and grade | Final score, max combo, grade, accuracy consistent |
| **22** | Retry Flow | Trigger `game_inst._on_retry_pressed()` | Re-initializes song; resumes gameplay cleanly |
| **23** | Exit to Menu | Call `GameController.exit_to_menu()` | Clears song state; returns cleanly to `MAIN_MENU` |
| **24** | Settings and persistence | Change Music slider and inspect `user://settings.cfg` | Music/SFX controls load; changed volume persists |
| **25** | Calibration screen | Instantiate calibration scene and verify tap controls | Calibration UI loads and is connected to calibration service |
| **26** | Player profile | Load profile scene after a completed run | Statistics and personal bests render from persisted local data |

---

## 3. Execution Command

To run this validation plan headlessly in any environment with Godot 4.3:

```bash
godot --headless --path godot_project "res://scenes/RuntimeSmokeTest.tscn"
```

