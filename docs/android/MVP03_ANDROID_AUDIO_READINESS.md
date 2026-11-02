# MVP-03 ANDROID AUDIO READINESS (Agent 07)

Project: PROJECT RHYTHM
Owner: Agent 07 (Android & Release Engineer)
Branch: agent/project-rhythm-android
Worktree: /home/abhaysawant/project-rhythm-android
Platform: Android
Engine: Godot 4 (ADR-001)
MVP: MVP-03 — Android Audio Readiness

## Purpose

Document the Android audio configuration, latency considerations, supported sample rates, and device-level audio testing procedures for Project Rhythm. This is a readiness document: it specifies what must be verified once the Android toolchain and a test device are available. It does not report measured device audio performance, because no device evidence exists yet.

## Evidence rule

No Android audio performance claim (latency in ms, actual output sample rate, measured jitter, measured drift) is stated as fact for this project's device unless it is backed by a device measurement. All values below that are not tied to an in-repo measurement are labeled "reference only — pending device verification (B-04)". Godot 4 defaults and Android platform reference values are identified as such.

## Status summary

| Item | Status | Blocker | Evidence |
|------|--------|---------|----------|
| Audio architecture (AudioSync / OffsetCalibration) | Documented, in-repo | None (code review only) | godot_project/scripts/AudioSync.gd, OffsetCalibration.gd |
| Android export preset (audio-relevant fields) | Documented, not applied | B-01, B-02 | android/EXPORT_PRESET.md |
| Supported sample rates (Godot default) | Reference only | B-04 (device measurement) | Godot 4 default 44100 Hz |
| Android output sample rate | Not measured | B-04 | Pending device evidence |
| Audio latency / buffer | Not measured | B-01, B-02, B-04 | Pending device evidence |
| Hit-window calibration (±50 / ±100 ms) | Target only | B-04 | docs/TESTING_STRATEGY.md |
| Device-level audio testing (T-23) | Not runnable | B-01, B-02, B-04 | Pending device |

**Overall: BLOCKED.** Audio readiness cannot be verified on a device until Godot 4 (B-01), the Android SDK (B-02), and an Android device/emulator (B-04) are installed.

## Audio architecture review

### AudioSync.gd (autoload singleton)

File: godot_project/scripts/AudioSync.gd

- Authoritative audio clock derived from the hardware audio position each process tick:
  `current_audio_time = get_playback_position() + AudioServer.get_time_since_last_mix()`
- `adjusted_system_time = current_audio_time - local_hardware_offset`
- Decoupled from frame-delta accumulation; no frame-delta is used for note timing.
- `APPROACH_TIME = 1.5` s (visible note window ahead of the hit line).
- `local_hardware_offset` is loaded from `user://settings.cfg` `[audio] user_offset` on `_ready()` and applied on every `_process()` tick.
- Wired to an `AudioStreamPlayer` via `initialize_playback_channel($AudioPlayer)` in GameScene.gd; playback started/stopped by GameController.gd.

### OffsetCalibration.gd (autoload singleton)

File: godot_project/scripts/OffsetCalibration.gd

- Metronome-based user offset measurement: 0.5 s pulse interval, 12 taps, outlier threshold 250 ms.
- Mean signed tap delta persisted to `user://settings.cfg` `[audio] user_offset`.
- Reloads `AudioSync.local_hardware_offset` immediately without restart.

### project.godot (audio-relevant)

File: godot_project/project.godot

- `renderer/rendering_method="mobile"`
- `config/features=PackedStringArray("4.3", "Mobile")`
- `common/physics_ticks_per_second=60`
- `window/handheld/orientation=1`

No explicit Godot audio bus/sample-rate override is present in project.godot; Godot 4 audio defaults apply.

## Android audio configuration

### Godot 4 audio on Android (reference)

- Godot 4 runs audio on a dedicated audio thread via `AudioServer`.
- Default Godot output sample rate: 44100 Hz (Godot default, reference only).
- Android output sample rate is selected by the device/audio HAL; 44100 Hz and 48000 Hz are typical Android hardware rates, but the actual rate used by this project's device is not measured and may trigger resampling inside Godot or the Android audio pipeline.
- Master bus is the default `AudioBus` layout unless overridden in project.godot (none present).
- Audio is mixed and played back through an `AudioStreamPlayer` node in the gameplay scene.

Reference only — not measured on this project's device. Actual sample rate, buffer size, and output latency require a physical device/emulator (B-04).

### Export preset (audio-relevant)

Defined in android/EXPORT_PRESET.md:

- Package: com.projectrhythm.game
- Minimal permissions: VIBRATE (optional haptics), WAKE_LOCK (keep screen on). No INTERNET (offline-first).
- No audio-specific Android permissions are declared or required beyond standard audio output.
- Rendering method: Mobile.

project.godot alignment (Agent 00-owned): config/name, config/version, config/icon, window/handheld/orientation, renderer/rendering_method, config/features — do not modify without Agent 00 coordination.

## Supported sample rates and audio configuration

| Item | Value | Source | Device evidence |
|------|-------|--------|-----------------|
| Godot default output sample rate | 44100 Hz | Godot 4 default | Not measured |
| Android typical hardware rates | 44100 / 48000 Hz | Android platform reference | Not measured |
| Actual device output rate | TBD | Pending device measurement | Blocked (B-04) |
| Resampling behavior | TBD | Pending device measurement | Blocked (B-04) |
| Master bus layout | Default (Godot 4) | project.godot (no override) | Not verified on device |

All Android device rates above are reference values. The actual output sample rate, whether Godot resamples, and any rate-dependent timing impact must be measured on the target device before being treated as project evidence.

## Audio latency considerations

### Design approach (in-repo)

- Hardware-clock audio position (`get_playback_position() + AudioServer.get_time_since_last_mix()`) instead of frame-delta accumulation, to avoid drift across a full song.
- Persisted per-device `user_offset` calibration to absorb device-specific audio output latency.
- Hit-window targets: PERFECT ±50 ms, GOOD ±100 ms (calibrated), per docs/TESTING_STRATEGY.md.
- OffsetCalibration outlier threshold: 250 ms.

### Latency factors to verify on device (not measured)

- Android audio output buffer latency (AAudio/OpenSL ES), which contributes to the gap between mix time and speaker output.
- Godot audio thread scheduling jitter on the target device.
- Touch-to-registration latency (≤1 frame target per TESTING_STRATEGY.md).
- Audio sync drift across a full song (must stay within hit window).

None of these are measured for this project. Values quoted here are targets, not device evidence.

## Device-level audio testing procedures (T-23)

Blocked by B-01, B-02, B-04. These procedures are prepared for execution once unblocked.

### Prerequisites

1. Godot 4 installed with matching Android export templates (debug + release).
2. Android SDK installed: `adb`, platform-tools, build-tools, a platform (e.g., android-34).
3. `ANDROID_HOME` / `ANDROID_SDK_ROOT` set.
4. Physical Android device with USB debugging enabled, or an emulator, visible via `adb devices`.
5. Debug APK built: `godot --headless --export-android "Debug" godot_project/ build/HexaRhythm-debug.apk`.

### Procedure A — Installation and launch

1. `adb devices` — confirm one device/emulator is authorized.
2. `adb install -r build/HexaRhythm-debug.apk` — confirm success.
3. Launch app, confirm it reaches the main menu without crashing.
4. Confirm audio is audible (no silent output, no crash on playback start).

### Procedure B — Sample rate and output configuration capture (device evidence)

On the device, capture and record:

1. Android audio output sample rate in use (device/audio HAL rate).
2. Godot-reported effective sample rate / whether resampling occurred (log via Godot debug output or an added diagnostic print).
3. Audio buffer / output latency estimate if available via platform APIs.

Record these in the test log as device evidence. Do not fabricate values.

### Procedure C — Offset calibration on device

1. Open OffsetCalibration UI.
2. Run the 12-tap metronome calibration.
3. Confirm `user://settings.cfg` `[audio] user_offset` is written.
4. Confirm AudioSync reloads the offset on next startup without restart.

### Procedure D — Hit-window and sync-drift verification

1. Play a full song on device.
2. Verify hit judgment lands within PERFECT ±50 ms / GOOD ±100 ms windows (calibrated).
3. Verify audio sync drift stays within the hit window across the full song (no cumulative drift).
4. Verify audio stops on game over.

### Procedure E — Logging

Record per-device:
- Device model, Android API level, output sample rate.
- Measured offset (ms) from calibration.
- Hit-window results (PERFECT/GOOD/MISS distribution).
- Any drift or underrun observations.

## Blockers

| ID | Blocker | Effect on MVP-03 audio readiness | Owner |
|----|---------|----------------------------------|-------|
| B-01 | Godot 4 not installed | No APK build, no export templates, no headless export, no device audio verification | Agent 07 / user |
| B-02 | Android SDK not installed | No `adb`, no APK generation/install, no device testing | Agent 07 / user |
| B-04 | No Android device/emulator | No device audio measurement; all latency/sample-rate claims unverifiable | user |

## Cross-ownership notes

- godot_project/scripts/AudioSync.gd and OffsetCalibration.gd are audio implementation (Agent 03/Agent 07 scope); do not modify timing logic without coordination.
- project.godot (Agent 00-owned) fields relevant to Android export must not be modified by Agent 07.
- docs/TECHNICAL_ROADMAP.md (Agent 00-owned) blocker/status updates require Agent 00 coordination.
- All release/signing/production deployment require explicit user approval (android/RELEASE_SIGNING.md).
- Do not merge independently; submit audio readiness docs to Agent 00 for review.

## Next actions (unblocked when SDK/device present)

1. Agent 00 approves project.godot / export preset changes (if any).
2. User installs Godot 4 + Android SDK (docs/TECHNICAL_ROADMAP.md).
3. Provide Android device or emulator (B-04).
4. Build debug APK and install on device (Wave 3 T-22).
5. Execute Procedures A–E above; capture device evidence for sample rate, offset, hit windows, drift.
6. Update this document with measured device evidence; remove "reference only" labels where verified.
7. Submit to Agent 00 for review.
