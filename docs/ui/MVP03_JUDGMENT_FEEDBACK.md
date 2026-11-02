# MVP-03 Judgment Feedback

Owner: Agent 04 (UI/UX Engineer)
Branch: agent/project-rhythm-ui
Worktree: /home/abhaysawant/project-rhythm-ui
Status: Implemented + committed

## Scope

Deliver judgment-feedback polish for the gameplay scene (MVP-03, Agent 04 area of
responsibility per docs/management/ECOSYSTEM_AUDIT.md: "Complete GameScene.gd —
Agent 04 to wire HUD, pause, judgment feedback").

Files changed:
- godot_project/scripts/GameScene.gd — rewritten from stub to full HUD/judgment controller
- godot_project/scenes/GameScene.tscn — added TimingLabel and PauseOverlay nodes
- docs/ui/MVP03_JUDGMENT_FEEDBACK.md — this document

Files intentionally NOT changed:
- godot_project/scripts/ScoreManager.gd — Agent 05-owned autoload ("call it, never
  modify it", LaneManager.gd:30). Hit evaluation, scoring, combo, accuracy, and
  grade all remain here. Its `alignment_processed(rating, combo, accuracy)` signal
  is consumed as-is; it does not expose the per-hit error delta, so per-hit timing
  text is judgment-class based (see Timing feedback below).

## Requirements coverage

| MVP-03 item | Implementation |
|---|---|
| Judgment feedback improvement / accurate hit rating display | Color-coded ratings (PERFECT cyan, GOOD yellow, MISS red), pop-and-fade animation on every hit, score label shows score + live accuracy %, results screen shows grade |
| Combo and score feedback | Combo counter with pop animation, milestone bursts (COMBO x10/25/50/75/100), floating +300/+100 score text |
| Visual timing feedback | Rating colors encode timing quality, timing-window legend ("PERFECT ≤ 50 ms · GOOD ≤ 100 ms · MISS > 100 ms"), per-hit qualitative timing text (Hit on time / Slightly off / Missed window) |
| Pause/resume UI synchronized with gameplay state | Pause overlay, pause button text ("II"/"▶"), input gating, and audio pipeline all driven by GameStateManager.state_changed; pause button defers to GameController.pause_song()/resume_song() |

## Judgment feedback details

### Hit rating (_on_hit_evaluated)

Connected to `ScoreManager.alignment_processed(rating, combo, accuracy)`. On every
hit:

- `score_label` → `<final score>  (<accuracy>%)` — live accuracy updated per hit.
- `combo_label` → `Combo: <n>` (hidden when combo is 0).
- `rating_label` → the rating string, color-coded:
  - PERFECT: cyan (#00FFFF)
  - GOOD: yellow (#FFFF00)
  - MISS: red (#FF5959)
- Rating pop: scale 1.0 → 1.35 → 1.0 over 0.25 s, then alpha fades to 0 over
  0.45 s. Rapid consecutive hits restart (kill) the in-flight tween so the
  animation never gets stuck.
- Timing text (`timing_label`): "Hit on time" / "Slightly off" / "Missed
  window", same color coding, fades over 0.6 s.
- Floating score text ("+300" / "+300" / "+100") spawned above the rating label,
  drifts up 70 px and fades out over 0.7 s, then `queue_free()`. No float text
  for misses (0 points).
- Combo pop: `combo_label` scales 1.0 → 1.25 → 1.0 on each hit.

### Combo milestones

When the running combo hits 10, 25, 50, 75, or 100, a "COMBO x<n>!" burst label
spawns above the combo label, pops to 1.5× scale and fades out, then frees
itself.

### Song completion

`_on_song_completed(final_score, max_combo, accuracy, grade)`:
- Disables lane input, stops audio pipeline, transitions to RESULTS.
- `rating_label` → "Song Complete — Grade: <grade>".
- `combo_label` → final score / max combo / accuracy %.
- Timing label reverts to the window legend.

## Pause/resume synchronization

The authoritative state is `GameStateManager.current_state`; GameScene does not
keep a separate paused flag (the old local `_is_paused` was a desync risk).

- `GameStateManager.state_changed` is connected to `_on_game_state_changed`.
- Entering PAUSED: `_apply_pause_ui(true)` — input disabled, pause overlay
  shown, audio pipeline stopped.
- Leaving PAUSED: `_apply_pause_ui(false)` — input enabled, overlay hidden,
  audio pipeline started.
- The pause button text ("II" playing / "▶" paused) and disabled state are
  recomputed on every state change; the button is only enabled while PLAYING or
  PAUSED.
- The pause button itself defers to GameController: `pause_song()` when playing,
  `resume_song()` when paused. The overlay Resume/Retry/Main Menu buttons wire
  to the same handlers.
- Retry restarts the same song (prepare_song → spawn → audio → PLAYING) and
  resets all HUD labels. Main Menu exits via GameController.exit_to_menu() and
  changes scene to MainMenu.tscn.

Audio start/stop follows the existing AudioSync convention
(`start_audio_pipeline()` / `stop_audio_pipeline()`), consistent with the
MVP-01/MVP-02 foundation.

## Known constraints / open items

1. **No per-hit millisecond delta.** `ScoreManager.alignment_processed` carries
   `(rating, combo, accuracy)` only — the error delta is computed internally and
   not emitted (ScoreManager is Agent 05-owned and out of scope for this change).
   Per-hit timing text is therefore qualitative, not an exact "Early/Late N ms"
   readout. Extending the signal to include `error_delta_ms` would let GameScene
   show exact timing offsets.
2. **Chart assets pending.** `godot_project/assets/data/` is empty, so no song is
   currently playable end-to-end; the feedback logic is exercised through the
   ScoreManager → GameScene signal path rather than a live chart.
3. **Godot 4.3 is not installed in this environment**, so the scene could not be
   launched to visually verify animation timing. GDScript was reviewed against
   the 4.3 API (create_tween, Tween.kill/set_trans/set_ease/set_delay,
   theme_override_font_sizes dictionary access, Callable).
4. **Pause overlay input.** The dim ColorRect uses default mouse filtering, so
   taps pass through to the pause button behind the overlay; the overlay's own
   Resume/Retry/Main Menu buttons are reachable while paused.

## Testing

No GDScript test runner is configured in this repository (Python tests under
tests/ cover GameConfig only). Validation of this change is by code review:
signal signatures match ScoreManager (alignment_processed: rating/combo/accuracy;
sequence_tracking_concluded: final_score/max_combo/accuracy/grade), node paths
match GameScene.tscn (@onready lookups: HUD/ScoreLabel, HUD/ComboLabel,
HUD/RatingLabel, HUD/TimingLabel, HUD/PauseButton, PauseOverlay, LaneManager,
NoteSpawner, $PauseOverlay/VBox/Pause{Resume,Retry,Menu}Button).
