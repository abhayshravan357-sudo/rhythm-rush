# ANDROID DEVICE TEST PROCEDURE — PROJECT RHYTHM (Agent 07)

**Project:** HexaRhythm  
**Owner:** Agent 07 — Android & Release Engineer  
**Date:** 2026-11-04  
**Engine:** Godot 4.3  
**Target:** Android API Level 34 (Android 14) / Min SDK 24 (Android 7.0)

---

## 1. Purpose

Document the procedure for installing, launching, and testing HexaRhythm on a
physical Android device or emulator. This is the device-level validation step
(L5/L6) that follows Godot runtime validation (L4).

No APK can be generated or installed until B-02 (Android SDK packages) and
B-04 (device/emulator) are resolved.

---

## 2. Prerequisites

| Prerequisite | Status | Notes |
|--------------|--------|-------|
| Godot 4.3 installed | READY | `~/.local/bin/godot` |
| Android SDK cmdline-tools | READY | `~/.local/share/android-sdk/cmdline-tools/latest/` |
| Android platform-tools | PARTIAL | Installed; license acceptance pending |
| Android build-tools;34.0.0 | PARTIAL | Installed; license acceptance pending |
| Android platform;android-34 | PARTIAL | Installed; license acceptance pending |
| Android device or emulator | BLOCKED | B-04 — hardware dependency |
| Debug keystore | READY | `~/.local/share/godot/keystores/debug.keystore` |

---

## 3. Device Test Procedure

### 3.1 Connect Device

```bash
# Enable USB debugging on the Android device
# Connect via USB
adb devices
```

Expected output: device listed with serial number.

For emulator:
```bash
emulator -avd <avd_name>
adb devices
```

### 3.2 Generate Debug APK

```bash
export ANDROID_HOME=~/.local/share/android-sdk
export JAVA_HOME=~/.local/share/jdk-17

godot --headless --path godot_project --export-debug "Android" build/HexaRhythm-debug.apk
```

Expected output: `build/HexaRhythm-debug.apk` created.

### 3.3 Install APK

```bash
adb install -r build/HexaRhythm-debug.apk
```

Expected output: `Success`.

### 3.4 Launch Game

```bash
adb shell am start -n com.projectrhythm.game/org.godotengine.godot.GodotApp
```

Or tap the HexaRhythm icon on the device home screen.

### 3.5 Test Scenarios

| Test | Procedure | Expected Result |
|------|-----------|-----------------|
| App launch | Tap app icon | Main menu appears within 3 seconds |
| Main menu navigation | Tap Play, Song Selection, Settings | Each screen loads without crash |
| Song selection | Select a song | Song details shown, Play button enabled |
| Gameplay start | Tap Play on song | Four-lane gameplay scene loads |
| Tile spawning | Notes descend from top | Tiles appear in correct lanes |
| Touch input | Tap lanes as tiles reach hit line | Hit judgment (PERFECT/GOOD/MISS) |
| Pause/resume | Tap pause, then resume | Game pauses, audio pauses; resume restores |
| Game over/complete | Play song to end | Results screen shows score |
| Return to menu | Tap Main Menu from results | Back to main menu |
| Audio | Play song with headphones/speaker | Audio plays without crackle or drift |

### 3.6 Audio Latency Check

Tap tiles in time with the music. Hit judgments should align with the musical
beat. If taps consistently register early or late, use the audio latency
calibration in Settings to adjust.

### 3.7 Performance Check

Observe frame rate during gameplay. Target: 60 FPS sustained. Note any frame
drops, especially during simultaneous note events or hold notes.

### 3.8 Uninstall

```bash
adb uninstall com.projectrhythm.game
```

---

## 4. Expected Results

| Test | Pass Criteria |
|------|---------------|
| APK generation | `.apk` file created without errors |
| APK installation | `Success` from `adb install` |
| App launch | Main menu appears, no crash |
| Gameplay | Tiles spawn, touch input registers, scoring works |
| Pause/resume | Game pauses/resumes without audio glitches |
| Results | Score, combo, accuracy displayed correctly |
| Audio | Music plays, hit sounds trigger on time |
| Performance | 60 FPS sustained, no noticeable stutter |

---

## 5. Failure Modes

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| APK not generated | Missing Android SDK packages | Run `sdkmanager --licenses` and install packages |
| Install failed | Invalid package, architecture mismatch | Check `package/unique_name`, architectures |
| App crashes on launch | Missing assets, wrong package name | Check logcat for errors |
| No audio | Audio bus misconfigured | Check Godot audio bus setup |
| Tiles not syncing | Audio clock drift | Use audio latency calibration |
| Frame drops | Too many active nodes | Check object pool usage |

---

## 6. Log Collection

```bash
adb logcat -s GodotApp:D *:E
```

Capture logcat during gameplay for debugging crashes or audio issues.
