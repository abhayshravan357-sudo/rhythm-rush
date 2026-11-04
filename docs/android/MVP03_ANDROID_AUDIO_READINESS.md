# MVP-03 Android Audio Readiness — PROJECT RHYTHM

Project: HexaRhythm  
Owner: Agent 07 — Android & Release Engineer  
Date: 2026-11-02  
Verification: Documentation only — BLOCKED by B-01, B-02, B-04

## 1. Android Audio Configuration Review

No Android toolchain is installed (B-01: Godot 4 not installed; B-02: Android SDK not installed). The following configuration exists in `project.godot` and is relevant to Android audio:

- `config/features=PackedStringArray("4.3", "Mobile")` — mobile build target declared.
- `renderer/rendering_method="mobile"` — mobile renderer.
- `window/handheld/orientation=1` — portrait orientation.
- Audio uses Godot's default `AudioServer` with `AudioStreamPlayer`; `AudioSync` reads `get_playback_position()` + `get_time_since_last_mix()`.

No Android-specific audio overrides (OpenSL ES, AAudio, audio session, sample rate) are configured. Godot handles audio backend selection on Android automatically.

## 2. Audio Latency Investigation (Blocked)

Audio latency cannot be measured without:
- Godot 4 editor / export templates (B-01).
- Android SDK + adb + device or emulator (B-02, B-04).

`AudioSync` mitigates latency via:
- Hardware clock (`get_playback_position + get_time_since_last_mix`) instead of frame delta.
- User offset calibration (`OffsetCalibration` → `user://settings.cfg` `[audio] user_offset`).
- Drift analysis (`drift_ms()`) to detect clock skew over a session.

No fake Android audio performance claims are made. Latency figures are not reported because they cannot be measured in this environment.

## 3. Device-Level Audio Testing Procedures (Prepared, not executed)

When Godot 4 + Android SDK + device are available:

1. **Install:** Export debug APK; `adb install -r`.
2. **Touch:** Verify lane input registers (input gating, debounce).
3. **Audio:** Play a song; verify notes hit judgment line in sync with audio (compare `adjusted_system_time` vs heard beat).
4. **Offline:** Verify no network required (ADR-003 offline-first).
5. **Screen size:** Verify layout on multiple resolutions (stretch_mode canvas_items, aspect expand).
6. **Performance:** Monitor for GC pauses (object pooling eliminates runtime instantiation).
7. **Pause/resume:** Background/app-resume; verify audio and timing continue without corruption (`pause_audio_pipeline` / resume continuation).
8. **Song completion:** Verify `song_completed` fires at `song_duration`.

## 4. Supported Sample Rates and Audio Configuration

Not determined — requires Android device + `adb shell getprop` / audio tunnel query. Godot's `AudioServer` default configuration applies. `AudioSync` is sample-rate-agnostic (works in seconds).

## 5. No Fake Claims

Per acceptance criteria: no unverified Android audio performance or latency figures are reported in this document. All claims are limited to code behavior verifiable at L2 (unit) level.

## 6. Blocker Log

| ID | Blocker | Owner | Resolution |
|----|---------|-------|------------|
| B-01 | Godot 4 not installed | Agent 07 / user | Manual install required for editor/Android export |
| B-02 | Android SDK not installed | Agent 07 / user | Manual install required for APK generation |
| B-04 | No Android device/emulator | user | Required for device testing |

## 7. File Inventory

| File | Status |
|------|--------|
| docs/android/MVP03_ANDROID_AUDIO_READINESS.md | New (this document) |
| docs/android/ANDROID_BUILD_READINESS.md | Existing (verified, no changes) |
| `project.godot` | Existing (audio-relevant fields reviewed, no changes) |
