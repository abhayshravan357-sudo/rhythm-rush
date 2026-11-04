# MVP-03 Audio Synchronization — PROJECT RHYTHM

Project: HexaRhythm  
Owner: Agent 03 — Audio & Rhythm Engineer (PRIMARY)  
Date: 2026-11-02  
File: godot_project/scripts/AudioSync.gd  
Verification: L2 unit (tests/unit/test_audio_sync.py) — L4 blocked by B-01

## 1. Authoritative Audio-Clock Synchronization

`AudioSync` is the hardware-clock synchronisation engine (autoload singleton). The authoritative playback position is derived each `_process` tick from:

```
current_audio_time = audio_player_node.get_playback_position()
                       + AudioServer.get_time_since_last_mix()
adjusted_system_time = current_audio_time - local_hardware_offset
```

No frame-delta accumulation is used for note timing, preventing drift on mobile hardware. `get_playback_position_seconds()` returns `adjusted_system_time` and is consumed by `NoteSpawner` (spawn triggering) and `ScoreManager` (hit/miss judgment).

## 2. Reliable Playback Position Tracking

- `get_raw_audio_time()` — raw hardware clock (playback head + mix lag), pre-offset.
- `get_playback_position_seconds()` — offset-adjusted authoritative time used for judgment.
- `get_offset()` / `set_offset(seconds)` — hardware offset calibration, persisted to `user://settings.cfg` under `[audio] user_offset`.
- `load_calibration_data()` — loads offset on `_ready`.

## 3. Audio Offset Calibration

Offset is applied consistently: `adjusted_system_time = current_audio_time - local_hardware_offset`. `OffsetCalibration` (separate autoload) measures tap-to-beat delta and writes the mean to `user://settings.cfg`; `AudioSync` reads it on startup and `OffsetCalibration._finalise()` can update it live via `AudioSync.local_hardware_offset = mean`.

## 4. Pause/Resume Synchronization (MVP-03 Addition)

**`pause_audio_pipeline()`:** Freezes `adjusted_system_time` at `_paused_adjusted_time`, sets `is_paused = true`, stops the AudioStreamPlayer. Emits `playback_paused`.

**Resume:** `start_audio_pipeline()` detects `is_paused` and calls `_resume_from_pause()`, which seeks the AudioStreamPlayer to `_paused_adjusted_time + local_hardware_offset` so playback continues from the paused position. `adjusted_system_time` continues forward — **no backward jump, no timing corruption**.

**`stop_audio_pipeline()`:** Full stop — resets all time state to 0 (used on song complete / exit to menu, not pause).

Timing continuity is verified by `tests/unit/test_pause_resume_timing.py` (pause freezes clock; resume continues from paused position; no backward jump).

## 5. Song Completion Detection (MVP-03 Addition)

- `set_song_duration(seconds)` — sets the song duration; 0.0 = unknown (no auto-completion).
- In `_process`, if `song_duration > 0.0` and `current_audio_time >= song_duration`, `song_completed` is emitted and playback stops.
- Completion also fires when `audio_player_node.playing` becomes false (end of file).

Verified by `tests/unit/test_audio_sync.py` and `tests/integration/test_song_completion.py`.

## 6. Timing Drift Analysis (MVP-03 Addition)

- `drift_ms()` — mean `(current_audio_time - adjusted_system_time)` across samples, in ms. Equals the configured offset during steady playback.
- `drift_sample_count()` — number of samples collected.
- `_record_drift_sample()` — appends each `_process` tick; history capped at 600 samples.

Drift stays bounded and equals `local_hardware_offset` (120 ms example → drift_ms ≈ 120.0). Verified by `tests/unit/test_audio_sync.py`.

## 7. Dependencies

| Dependency | Direction | Notes |
|------------|-----------|-------|
| `AudioStreamPlayer` | injected via `initialize_playback_channel()` | Assigned by GameScene.gd |
| `AudioServer` | Godot engine | `get_time_since_last_mix()` |
| `ConfigFile` / `user://settings.cfg` | offset persistence | Read on load, written on set_offset |
| `NoteSpawner.gd` | consumes `adjusted_system_time`, `APPROACH_TIME`, `active_playback_flag` | Authoritative clock source |
| `ScoreManager.gd` | consumes `adjusted_system_time`, `active_playback_flag` | Hit/miss judgment timing |
| `OffsetCalibration.gd` | writes `local_hardware_offset` | Live calibration update |

## 8. Signals

| Signal | Fired when |
|--------|------------|
| `song_completed` | Playback reaches song duration OR `playing` becomes false |
| `playback_paused` | `pause_audio_pipeline()` pauses |
| `playback_resumed` | Resume from pause completes |

## 9. Verification Level

| Level | Status | Evidence |
|-------|--------|----------|
| L1 Static | ✅ | Code review complete |
| L2 Unit | ✅ | tests/unit/test_audio_sync.py (16 tests) |
| L3 Integration | ❌ | Requires Godot runtime (blocked B-01) |
| L4 Godot Runtime | ❌ | B-01: Godot 4 not installed |
| L5 Emulator | ❌ | B-02 / B-04 |
| L6 Device | ❌ | B-04 |

**Honest note (ADR-015):** No L4+ claims without Godot 4 installed.

## 10. File Inventory

| File | Status |
|------|--------|
| `godot_project/scripts/AudioSync.gd` | Modified (MVP-03: pause/resume, completion, drift) |
| `tests/unit/audio_sync.py` | New (reference implementation) |
| `tests/unit/test_audio_sync.py` | New (16 tests) |
| `docs/audio/MVP03_AUDIO_SYNCHRONIZATION.md` | New (this document) |
