# MVP-03 Audio Synchronization

**Owner:** Agent 03 — Audio & Rhythm Engineer
**Branch:** `agent/project-rhythm-audio`
**Worktree:** `/home/abhaysawant/project-rhythm-audio`
**Status:** Delivered

---

## 1. Overview

MVP-03 provides the authoritative playback-clock synchronization engine for
gameplay timing. The design rule is:

> **Gameplay timing is derived from the hardware audio clock, never from
> accumulated frame delta.**

`AudioSync.gd` is the autoload singleton that exposes the playback position used
by hit judgment (`ScoreManager`), note spawning (`NoteSpawner`), and visual
scrolling. It is the single source of truth for song position, calibration
offset, timing judgment windows, pause/resume integrity, song completion
detection, and timing-drift analysis.

---

## 2. Authoritative playback clock (`AudioSync.gd`)

### Clock source

`AudioSync._process` reads the hardware audio clock each process tick:

```gdscript
current_audio_time = (
    audio_player_node.get_playback_position()
    + AudioServer.get_time_since_last_mix()
)
adjusted_system_time = current_audio_time - local_hardware_offset
```

- `AudioStreamPlayer.get_playback_position()` — playback-head position in seconds.
- `AudioServer.get_time_since_last_mix()` — sub-frame mix lag, keeping the
  position current within the current render frame.
- `local_hardware_offset` — user calibration offset (from `OffsetCalibration`),
  subtracted to align the heard audio with the visual hit line.

**No frame-delta (`_delta`) accumulation is used for note timing.** Position is
always re-derived from the hardware clock, so frame-rate jitter and suspended
frames cannot corrupt song position.

### Public accessors

| Method | Purpose |
|--------|---------|
| `get_playback_position_seconds()` | Authoritative adjusted playback position (seconds) for hit judgment |
| `get_raw_audio_time()` | Raw audio clock position, pre-offset |
| `get_offset()` / `set_offset(seconds)` | User calibration offset (persisted to `user://settings.cfg`) |
| `get_approach_time()` | Visible note approach window (1.5 s) |
| `is_playing()` | Whether playback is active and the player node is playing |
| `is_paused()` | Whether playback is paused |

`get_playback_position_seconds()` is consumed by:
- `ScoreManager.process_action_input()` — hit judgment
- `ScoreManager._process()` — auto-miss detection
- `NoteSpawner._process()` — note spawning and visual scrolling

---

## 3. Explicit timing judgment windows

Judgment windows are defined once in `AudioSync.gd` as the canonical source and
read by `ScoreManager.gd` at call time, so the two systems can never diverge:

| Rating | Window (one-sided delta from note timestamp) | Points | Combo |
|--------|----------------------------------------------|--------|-------|
| PERFECT | `≤ JUDGMENT_WINDOW_PERFECT` (50 ms) | 300 | +1 |
| GOOD | `≤ JUDGMENT_WINDOW_GOOD` (100 ms) | 100 | +1 |
| MISS | `> JUDGMENT_WINDOW_GOOD` | 0 | reset |

`ScoreManager.gd` previously duplicated these constants (`HIT_WINDOW_PERFECT`,
`HIT_WINDOW_GOOD`). They were removed in favor of
`AudioSync.get_judgment_window_perfect()` / `AudioSync.get_judgment_window_good()`
so a single calibration point governs all judgment.

---

## 4. Deterministic note judgments & single-resolution guarantee

### Prevent double-judgment

`ScoreManager` owns hit/miss resolution. Each note is tracked by index in
`resolved_flags: Dictionary` (`note_index → resolved bool`).

- `process_action_input()` marks the chosen note resolved via
  `_evaluate_hit_precision()`, which early-returns if the note is already
  resolved (`resolved_flags.get(note_index, false)`).
- `_process()` auto-misses unresolved notes whose playback time has passed the
  GOOD window (`playback_time > note_time + GOOD_WINDOW`), also gated on
  `resolved_flags`.
- `_register_miss()` is likewise gated on `resolved_flags`.

Result: **a note can be judged at most once** — whether by a user tap or by
auto-miss expiration. Duplicate taps on the same resolved note are no-ops.

### Determinism

Judgment reads `AudioSync.adjusted_system_time` (hardware clock), not frame
delta, so the same tap at the same playback position always yields the same
rating regardless of frame rate.

---

## 5. Pause/resume without timing corruption

### Problem (pre-MVP-03)

`GameController.pause_song()` / `resume_song()` only transitioned the game
state machine; they never paused the `AudioStreamPlayer` or froze
`AudioSync.adjusted_system_time`. While the game was "paused", the audio clock
kept advancing and `adjusted_system_time` kept running, so resume would land
at a corrupted, ahead-of-time song position.

### Fix

`AudioSync.gd` now exposes:

- `pause_audio_pipeline()` — calls `audio_player_node.pause()`, sets `is_paused =
  true`, emits `playback_paused`. While paused, `_process` returns early, so
  `adjusted_system_time` freezes at the pause position and no drift or
  completion is reported.
- `resume_audio_pipeline()` — calls `audio_player_node.play()` (Godot resumes
  from the paused playback head), clears `is_paused`, emits
  `playback_resumed`, and re-anchors the drift baseline.
- `toggle_pause()` — convenience toggle.
- `stop_audio_pipeline()` — also clears `is_paused`.

`GameController.pause_song()` / `resume_song()` now call
`AudioSync.pause_audio_pipeline()` / `AudioSync.resume_audio_pipeline()` so
pause/resume is synchronized end-to-end and song position is preserved across
the pause boundary.

---

## 6. Song completion detection

`AudioSync._process` detects natural song completion:

```gdscript
if not audio_player_node.playing:
    active_playback_flag = false
    is_paused = false
    emit_signal("song_completed")
    return
```

This fires only when the player is actively playing (not paused, not manually
stopped) and `AudioStreamPlayer.playing` becomes `false`, i.e. the stream
reached its natural end. `song_completed` is **not** emitted during pause, and
`stop_audio_pipeline()` does not emit it (manual stop ≠ completion).

`ScoreManager._process` also finalizes the scoring sequence when every note is
resolved (`is_sequence_complete()` → `sequence_tracking_concluded`), providing
a second, judgment-driven completion signal independent of the audio stream.

---

## 7. Timing drift analysis

Mobile audio hardware can run the audio clock at a slightly different rate than
the system wall clock (different crystal oscillators), causing long-term drift
between `current_audio_time` and real time.

`AudioSync._record_drift_sample()` runs each process tick while playing and
compares the audio-clock delta against the wall-clock delta:

```gdscript
drift_sample = audio_clock_delta - wall_clock_delta   # seconds
```

- Positive drift = audio clock runs ahead of wall clock.
- Negative drift = audio clock runs slow.

### Accessors

| Method | Purpose |
|--------|---------|
| `get_timing_drift_ms()` | Average drift in milliseconds over the current sample window |
| `get_drift_sample_count()` | Number of drift samples in the current window |

The window rolls every `DRIFT_MAX_SAMPLES` (120) ticks so the reported value
reflects recent behavior rather than being dominated by early samples. Drift is
reset (re-anchored) on `start_audio_pipeline()` and `resume_audio_pipeline()`.

---

## 8. Audio offset calibration (`OffsetCalibration.gd`)

`OffsetCalibration` performs metronome-based latency measurement:

1. A 0.5 s metronome pulse fires (`calibration_tick` signal).
2. The user taps in time; each tap's signed delta from the beat is recorded.
3. After 12 taps (outliers > 250 ms discarded), the mean delta is computed.
4. The mean is persisted to `user://settings.cfg` under `[audio] user_offset`.
5. `AudioSync.load_calibration_data()` reads `user_offset` on startup and
   subtracts it from every `adjusted_system_time` calculation.

`OffsetCalibration._finalise()` also reloads the offset immediately via
`AudioSync.local_hardware_offset = mean` so calibration takes effect without a
restart. `AudioSync.set_offset()` offers the same path with persistence.

### Compatibility

`OffsetCalibration.gd` writes `AudioSync.local_hardware_offset`, a public
variable that still exists after the MVP-03 refactor. `AudioSync` reads the
same `user://settings.cfg` key `[audio] user_offset`. No changes were required
in `OffsetCalibration.gd`.

---

## 9. ChartLoader.gd compatibility

`ChartLoader.gd` performs JSON chart IO, validation, and window slicing. It
does not reference `AudioSync` internals. Its `get_notes_in_window(time_start,
time_end)` works in seconds and composes cleanly with
`AudioSync.get_playback_position_seconds()` for spawning decisions. `NoteSpawner`
calls `get_notes_in_window`-equivalent logic internally against
`AudioSync.adjusted_system_time`.

No changes were required in `ChartLoader.gd`.

---

## 10. Files changed

| File | Change |
|------|--------|
| `godot_project/scripts/AudioSync.gd` | Refactored: added judgment-window constants, pause/resume (`pause_audio_pipeline`, `resume_audio_pipeline`, `toggle_pause`, `is_paused`), timing-drift analysis (`get_timing_drift_ms`, `get_drift_sample_count`), refined song-completion detection, consolidated offset persistence (`_persist_offset`) |
| `godot_project/scripts/ScoreManager.gd` | Removed duplicated `HIT_WINDOW_PERFECT`/`HIT_WINDOW_GOOD` constants; now reads windows from `AudioSync` at call time (single canonical source) |
| `godot_project/scripts/core/GameController.gd` | `pause_song()`/`resume_song()` now call `AudioSync.pause_audio_pipeline()`/`resume_audio_pipeline()` |
| `docs/audio/MVP03_AUDIO_SYNCHRONIZATION.md` | New: this document |

No changes to `ChartLoader.gd`, `OffsetCalibration.gd`, or `NoteSpawner.gd` were required.

---

## 11. Verification

- Python QA suite (`pytest`) baseline: 46 passed. No test exercises `AudioSync.gd`
  directly (Godot autoloads), but `tests/unit/scoring_engine.py` and
  `tests/unit/test_scoring.py` re-implement the judgment rules; the
  MVP-03 window values (50 ms / 100 ms) match `scoring_engine.py` and the
  updated `ScoreManager.gd`.
- Godot is not installed in this environment, so GDScript could not be executed
  in-engine. The GDScript was reviewed for API consistency across
  `AudioSync.gd`, `ScoreManager.gd`, `NoteSpawner.gd`, `GameController.gd`,
  `OffsetCalibration.gd`, and `ChartLoader.gd`.
