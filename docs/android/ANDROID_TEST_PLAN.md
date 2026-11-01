# ANDROID TEST PLAN — PROJECT RHYTHM (Agent 07)

Project: PROJECT RHYTHM
Owner: Agent 07 (Android & Release Engineer) with Agent 06 (QA & Performance Engineer)
Branch: agent/project-rhythm-android
Worktree: /home/abhaysawant/project-rhythm-android
Platform: Android

## Scope

Test plan for the Android build of Project Rhythm. Covers build verification, device installation, gameplay/QA test coverage inherited from docs/TESTING_STRATEGY.md (Agent 06-owned), and device-test prerequisites. Environment is blocked; no device testing can run until unblocked.

## Test levels

Test ownership and execution follow docs/TESTING_STRATEGY.md.

| Level | Location | Coverage | Owner | Status |
|-------|----------|----------|-------|--------|
| Unit tests | tests/unit/ | Scoring hit windows, combo, accuracy, grade, ChartLoader | Agent 06 | Runnable (Python) |
| Integration tests | tests/integration/ | AudioSync, LaneManager, NoteSpawner, ScoreManager integration, pause/resume | Agent 06 | Runnable (Python) |
| Gameplay tests | tests/gameplay/ | 4-lane touch, hold notes, simultaneous notes, miss detection, audio stop on game over | Agent 06 | Runnable (Python) |
| Device/perf tests | Android device/emulator | 60 FPS, input latency, audio sync drift, memory, startup, aspect ratio, battery | Agent 06 / Agent 07 | Blocked (B-01, B-02, B-04) |

## Acceptance criteria (inherited from TESTING_STRATEGY.md)

| Criterion | Target |
|-----------|--------|
| Hit-window accuracy | PERFECT ±50 ms, GOOD ±100 ms (calibrated) |
| Frame rate | 60 FPS stable during gameplay |
| Audio sync drift | Within hit window across full song |
| Touch response | ≤1 frame input-to-registration latency |
| Memory | No growth over repeated plays (object pooling) |
| Crash rate | Zero crashes on normal playthrough |
| Device test | Verified on at least one physical Android device |

## Android-specific test steps

1. Build verification (blocked by B-01, B-02)
   - Godot 4 + Android SDK installed
   - Export templates installed (debug + release, matching Godot version)
   - `godot --headless --export-android "Debug" godot_project/ build/HexaRhythm-debug.apk` succeeds
   - Output: `build/HexaRhythm-debug.apk`

2. Install verification (blocked by B-02, B-04)
   - `adb devices` shows an emulator or physical device with USB debugging enabled
   - `adb install build/HexaRhythm-debug.apk` succeeds
   - App launches and reaches main menu

3. Gameplay/QA device tests (blocked by B-04)
   - Execute tests/gameplay/ scenarios on device via Godot headless / GUT or equivalent
   - Verify 60 FPS, input latency, audio sync, memory stability
   - QA (Agent 06) signs off only after device verification

4. Release candidate (pending user approval)
   - Release keystore created only after user approval
   - `godot --headless --export-android "Release" ...` produces signed APK
   - Release APK installed and verified on device before distribution sign-off

## Blockers

| ID | Blocker | Effect on testing | Owner |
|----|---------|-------------------|-------|
| B-01 | Godot 4 not installed | No APK build; no headless export; no export templates | Agent 07 / user |
| B-02 | Android SDK not installed | No `adb`, no APK generation/signing | Agent 07 / user |
| B-04 | No Android device/emulator | No device testing (T-23); QA sign-off impossible | user |

## Dependencies & cross-ownership

- docs/TESTING_STRATEGY.md (Agent 06) defines test levels, acceptance criteria, and independence (Agent 06 does not author code under test).
- android/BUILD_READINESS.md defines the debug APK build path.
- android/RELEASE_SIGNING.md governs release APK signing (user approval mandatory).
- project.godot (Agent 00-owned) fields relevant to Android export must not be modified by Agent 07.

## Exit criteria

- Debug APK builds cleanly and installs on a physical Android device.
- Gameplay/QA tests pass on device; 60 FPS, audio sync within hit window, zero crashes.
- QA (Agent 06) signs off after device verification.
- Release APK only after user sign-off.
