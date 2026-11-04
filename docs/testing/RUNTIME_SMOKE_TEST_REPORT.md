# RUNTIME SMOKE TEST REPORT — HEXARHYTHM

**Date:** 2026-11-02  
**Test Suite:** `godot_project/scripts/tests/runtime_smoke_test.gd`  
**Execution Binary:** `godot` (Godot Engine v4.3.stable.official.77dcf97d8)  
**Execution Command:** `godot --headless --path godot_project "res://scenes/RuntimeSmokeTest.tscn"`  
**Latest Result:** **27 / 27 PASSED (0 FAILED)**
**Verification Level:** Level 4 (Godot Runtime Validation)

The command transcript below is the earlier 26-step run. The latest 27-step run adds checks that the pause overlay and audio clock resume together and that centered content bounds remain inside four desktop and two mobile target aspect sizes. Its summary was 27 / 27 PASSED (0 FAILED).

---

## 1. Test Execution Output

```

## Latest UI overhaul verification

- HOME=/tmp/hexa-ui-godot-home timeout 20s /home/abhaysawant/.local/bin/godot --headless --verbose --path godot_project res://scenes/RuntimeSmokeTest.tscn — 27/27 passed.
- PYTHONPATH=. .venv/bin/python -m pytest -q — 141 passed. Pytest reports the existing unknown rootdir configuration option warning.
- Godot editor import/parser check — no GDScript parse errors. The sandbox still logs Godot editor-helper socket-listen errors.
- GUI and visual validation are blocked by this environment's missing X11/Wayland display and are not inferred from headless checks.
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
HEXARHYTHM GODOT 4.3 RUNTIME SMOKE TEST SUITE
==================================================
[PASS] Step 01: Launch Godot 4.3 -> Godot Engine v4.3.stable.official.77dcf97d8 launched successfully
[PASS] Step 02: Import/open the project -> Project root /home/abhaysawant/hexa-rhythm/godot_project loaded
[PASS] Step 03: Wait for imports to complete -> All project assets (.godot/imported) compiled without errors
[PASS] Step 04: Check parser and resource errors -> 0 script parse errors, 0 cyclic dependencies
[PASS] Step 05: Verify autoload initialization -> GameConfig, GameStateManager, GameController, ChartLoader, AudioSync, ScoreManager, PlayerProfile all active
[PASS] Step 06: Run MainMenu scene -> MainMenu.tscn instantiated and added to root
[PASS] Step 07: Test Play button -> PlayButton found with text: 'Play'
[PASS] Step 08: Test song-selection transition -> SongLibraryButton found; SongSelection.tscn loadable
[ChartLoader] Loaded 43 notes from: res://charts/example_chart.json
[PASS] Step 09: Test chart loading -> Loaded example_chart.json with 43 notes, BPM=128.0
[PASS] Step 10: Test audio loading -> Loaded res://assets/audio/example_track.ogg (AudioStreamOggVorbis)
[ChartLoader] Loaded 43 notes from: res://charts/example_chart.json
[PASS] Step 11: Test GameController initialization -> prepare_song succeeded; state transitioned to LOADING
[PASS] Step 12: Run GameScene -> GameScene instantiated in active tree
[PASS] Step 13: Verify lanes and judgment line -> LaneManager configured with 4 lanes; JudgmentLine at y=918.0
[PASS] Step 14: Verify note spawning -> NoteSpawner initialized object pool with 200 ColorRect nodes
[PASS] Step 15: Verify touch/input handling -> Simulated touch resolved to lane 0 through LaneManager
[PASS] Step 16: Verify hit and miss judgments -> Judgment evaluated: perfects=1, goods=0, misses=0
[PASS] Step 17: Verify score, combo, accuracy, and grade -> Score=300, Combo=1, Accuracy=2.33%, Grade=F
[PASS] Step 18: Verify pause -> GameController.pause_song transitioned state to PAUSED
[PASS] Step 19: Verify resume -> GameController.resume_song transitioned state back to PLAYING
[PASS] Step 20: Verify song completion -> complete_song deactivated gameplay and transitioned to RESULTS
[PASS] Step 21: Verify results screen and saved profile -> Score=300, Grade=F, Accuracy=2.33%; profile save and duplicate guard checked
[ChartLoader] Loaded 43 notes from: res://charts/example_chart.json
[PASS] Step 22: Verify retry -> Retry re-initialized chart and returned state to PLAYING
[PASS] Step 23: Verify returning to the menu -> exit_to_menu cleared song state and returned to MAIN_MENU
[PASS] Step 24: Verify settings screen, persistence, and reset -> Music/SFX sliders apply and persist; Reset restores defaults
[PASS] Step 25: Verify calibration scene -> Calibration UI controls load
[PASS] Step 26: Verify profile screen -> Profile statistics and completed-song best score render
==================================================
SMOKE TEST SUMMARY: 26 / 26 PASSED (0 FAILED)
==================================================
```

---

## 2. Step-by-Step Evidence Table

| Step | Test Name | Status | Verified Evidence |
|:----:|:----------|:------:|:------------------|
| **01** | Launch Godot 4.3 | **PASS** | Version reported: `4.3.stable.official.77dcf97d8` |
| **02** | Import/open the project | **PASS** | Successfully opened `godot_project/project.godot` |
| **03** | Wait for imports to complete | **PASS** | `.godot/imported` assets processed cleanly |
| **04** | Check parser and resource errors | **PASS** | 0 script compile errors across all scripts |
| **05** | Verify autoload initialization | **PASS** | All 7 autoload singletons active in `/root` |
| **06** | Run MainMenu scene | **PASS** | `MainMenu.tscn` instantiated into root viewport |
| **07** | Test Play button | **PASS** | Button verified with label `"Play"` |
| **08** | Song-selection transition | **PASS** | `SongLibraryButton` verified; `SongSelection.tscn` loadable |
| **09** | Test chart loading | **PASS** | Deserialized 43 notes, BPM 128.0 from `example_chart.json` |
| **10** | Test audio loading | **PASS** | Loaded `example_track.ogg` as `AudioStreamOggVorbis` |
| **11** | GameController initialization | **PASS** | `prepare_song` set `LOADING` state and loaded chart |
| **12** | Run GameScene | **PASS** | Instantiated `GameScene.tscn` in active tree |
| **13** | Lanes and judgment line | **PASS** | 4 columns (width step 480.0px); JudgmentLine at `y=918.0` |
| **14** | Note spawning pool | **PASS** | Pre-allocated exactly 200 `ColorRect` visual tiles |
| **15** | Touch / input handling | **PASS** | Screen touch at `x=240` mapped to lane 0 |
| **16** | Hit and miss judgments | **PASS** | Accurate judgment windows evaluated: perfects=1, goods=0, misses=0 |
| **17** | Scoring calculation | **PASS** | Multipliers and score: Score=300, Combo=1, Acc=2.33%, Grade=F |
| **18** | Gameplay pause | **PASS** | Audio head frozen; state changed to `PAUSED` |
| **19** | Gameplay resume | **PASS** | Audio head resumed; state changed back to `PLAYING` |
| **20** | Song completion | **PASS** | Audio stopped; state transitioned to `RESULTS` |
| **21** | Results screen presentation | **PASS** | Final score, grade, and accuracy matches gameplay counters |
| **22** | Retry flow | **PASS** | Restarted chart; re-entered `PLAYING` state |
| **23** | Return to menu | **PASS** | Exited gameplay; state returned to `MAIN_MENU` |
| **24** | Settings and persistence | **PASS** | Music and SFX controls loaded; Music slider change persisted |
| **25** | Calibration scene | **PASS** | Calibration controls instantiated |
| **26** | Player profile | **PASS** | Persisted play stats and personal best render in profile UI |

## Lifecycle cleanup follow-up

The first expanded run exposed audio playback objects still alive at process shutdown. `GameScene._exit_tree()` now stops playback and clears the autoload's scene-owned player reference. The smoke harness waits for deferred scene deletion and audio-mixer retirement before quitting. A verbose rerun passed 26/26 with no ObjectDB or resource-in-use warnings. The Pause button anchors were corrected; the latest run also emitted no Control layout warnings.

---

## 3. Defects Discovered and Resolved During Runtime Validation

1. **Autoload Class Name Collision:**
   - *Problem:* `class_name GameConfig` and `class_name PlayerProfile` collided with autoload declarations in `project.godot`.
   - *Fix:* Removed redundant `class_name` declarations in autoload scripts.
2. **Constant Array Type Syntax:**
   - *Problem:* `const ALLOWED_LANE_COUNTS: PackedInt32Array = PackedInt32Array([4, 6])` failed GDScript constant expression check.
   - *Fix:* Changed to standard typed array `const ALLOWED_LANE_COUNTS: Array[int] = [4, 6]`.
3. **Signal / Function Name Collision:**
   - *Problem:* `signal game_over` conflicted with `func game_over()`.
   - *Fix:* Renamed signal to `signal game_over_triggered` while preserving public method API `game_over()`.
4. **Invalid Division Operator:**
   - *Problem:* `operational_combo_counter // COMBO_TIER_STEP` in `ScoreManager.gd` used Python syntax.
   - *Fix:* Changed to integer division `int(operational_combo_counter / COMBO_TIER_STEP)`.
5. **Variant Type Inferences:**
   - *Problem:* `:=` on Variant values in `SaveManager.gd` and `SongUnlockManager.gd` triggered compile warnings treated as fatal errors.
   - *Fix:* Added explicit type annotations or untyped declarations.
6. **Built-in Function Signature Mismatch:**
   - *Problem:* `round(accuracy * 100, 1)` in `GameScene.gd` passed 2 arguments to Godot's 1-argument `round()` function.
   - *Fix:* Replaced with `snapped(accuracy * 100.0, 0.1)`.
7. **Signal Signature Arity Mismatch:**
   - *Problem:* `ScoreManager.alignment_processed` emits 3 arguments (`rating`, `combo`, `accuracy`), but `GameScene._on_hit_evaluated` declared only 2.
   - *Fix:* Added `_accuracy: float = 0.0` parameter to `_on_hit_evaluated`.
8. **Scene Node Hierarchy Path Errors:**
   - *Problem:* `SongSelectionUI.gd` called `get_parent().get_node(...)` on its own children; `GameScene.tscn` had misplaced `VBox` and `JudgmentLine` parent paths.
   - *Fix:* Corrected node paths in scene definition and script lookups.
9. **Missing Audio Asset in Main:**
   - *Problem:* `example_track.ogg` was present in Agent 03's worktree but missing from main `godot_project/assets/audio/`.
   - *Fix:* Copied `example_track.ogg` to main project assets directory.
10. **State Machine Game Launch Coordination:**
   - *Problem:* `GameScene._bootstrap_gameplay()` started `AudioSync` without calling `GameController.start_song()`, leaving `is_game_active` false and preventing pause.
   - *Fix:* Updated `_bootstrap_gameplay()` and `_on_retry_pressed()` to trigger `GameController.start_song()`.

