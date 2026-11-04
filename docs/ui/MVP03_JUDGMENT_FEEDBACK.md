# MVP-03 Judgment Feedback — PROJECT RHYTHM

Project: HexaRhythm  
Owner: Agent 04 — UI/UX Engineer  
Date: 2026-11-02  
Files: godot_project/scripts/GameScene.gd  
Verification: L1 static — L4 blocked by B-01 (scenes not loadable without Godot)

## 1. Judgment Feedback Improvement (MVP-03)

`GameScene._on_hit_evaluated(rating, combo)` renders judgment feedback:

- `rating_label.text` set to the rating (PERFECT / GOOD / MISS).
- Rating color by judgment:
  - PERFECT → cyan (`#29b6f6` equivalent)
  - GOOD → yellow
  - MISS → red
- `modulate:a` tweens from 1.0 to 0.0 over 0.4 s for a fade-out pulse.
- Combo feedback: on every 10-hit milestone (`combo % 10 == 0`), combo label flashes.
- Judgment-line flash: `$JudgmentLine` modulates to white briefly on each hit.

## 2. Accurate Hit Rating Display

Ratings come from `ScoreManager.alignment_processed(rating, combo, accuracy)`:
- `rating_label` shows the rating text.
- `score_label` shows `ScoreManager.get_final_score()`.
- `combo_label` shows "Combo: N" (empty when combo is 0).

Accuracy shown in `_on_hit_evaluated` via `ScoreManager.get_accuracy()` (passed through the signal).

## 3. Combo and Score Feedback Improvement

- Score updates in real time on each judgment (`score_label.text = str(get_final_score())`).
- Combo milestone flash (every 10 hits) via tween on `combo_label.modulate:a`.
- On song completion, `combo_label` shows "Final Score: N | Max Combo: M | Accuracy: X%".

## 4. Visual Timing Feedback

- `rating_label` modulate pulse (1.0 → 0.0 over 0.4 s).
- `judgment_line` (`$JudgmentLine` ColorRect) flashes white on each hit.
- All feedback driven by ScoreManager signals — UI does not independently manipulate scoring logic (ADR-009 preserved).

## 5. Pause/Resume UI Sync with Gameplay State (MVP-03)

- `GameController.song_paused` signal → `_on_controller_paused()` → `_toggle_pause_ui(true)`.
- `GameController.song_completed` signal → `_on_controller_completed()` → results transition.
- `_toggle_pause_ui(paused)`:
  - Sets `lane_manager.set_input_enabled(not paused)`.
  - Sets `pause_button.text` ("▶" when paused, "II" when playing).
  - Pauses/resumes `AudioSync` via `pause_audio_pipeline()` / `start_audio_pipeline()`.
- Pause button pressed → `GameController.pause_song()` / `GameController.resume_song()` (lifecycle-owned).

## 6. Signals Consumed

| Signal | Source | Handler | Purpose |
|--------|--------|---------|---------|
| `alignment_processed(rating, combo, accuracy)` | ScoreManager | `_on_hit_evaluated` | Update HUD + judgment feedback |
| `sequence_tracking_concluded(score, max_combo, accuracy, grade)` | ScoreManager | `_on_song_completed` | Results transition |
| `song_paused(song_id)` | GameController | `_on_controller_paused` | Pause UI sync |
| `song_completed(song_id)` | GameController | `_on_controller_completed` | Completion UI sync |

## 7. Dependencies

| Dependency | Direction | Notes |
|------------|-----------|-------|
| `AudioSync` | GameScene → AudioSync | `initialize_playback_channel`, `start/stop/pause_audio_pipeline` |
| `ScoreManager` | GameScene → ScoreManager | Signal consumption only |
| `GameController` | GameScene → GameController | `current_chart`, `prepare_song`, `pause_song`, `resume_song`, `exit_to_menu` |
| `GameStateManager` | GameScene → GameStateManager | `transition_to(PLAYING/RESULTS)` |
| `LaneManager` | GameScene → LaneManager | `set_input_enabled` |
| `NoteSpawner` | GameScene → NoteSpawner | `start_spawning_sequence` |

## 8. Verification Level

| Level | Status | Evidence |
|-------|--------|----------|
| L1 Static | ✅ | Code review complete; signal wiring consistent |
| L2 Unit | ❌ | GameScene is Godot-node-dependent; no pure-Python equivalent |
| L3 Integration | ❌ | Requires Godot runtime (blocked B-01) |
| L4 Godot Runtime | ❌ | B-01: Godot 4 not installed |

**Honest note:** GameScene.gd is Godot-node-dependent (`@onready` node paths, `create_tween`, `Label`, `Button`, `ColorRect`). L2+ validation requires Godot 4.

## 9. File Inventory

| File | Status |
|------|--------|
| `godot_project/scripts/GameScene.gd` | Modified (MVP-03: judgment colors, combo flash, judgment-line flash, pause/resume UI sync) |
| `godot_project/scenes/GameScene.tscn` | Existing (verified — references HUD, LaneManager, NoteSpawner, AudioPlayer, JudgmentLine) |
| `docs/ui/MVP03_JUDGMENT_FEEDBACK.md` | New (this document) |
