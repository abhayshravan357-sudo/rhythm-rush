# Skill: Android Development — Build, Export, and Device Setup

Purpose: Configure Godot 4 for Android export, generate APKs, manage signing/versioning, and verify installation on devices for PROJECT RHYTHM.

## Scope

- Godot 4 Android export preset configuration
- APK generation (debug and release)
- Keystore / signing setup
- Version code / version name management
- adb install / launch verification
- Minimal Android permissions

## Procedure: Install Android SDK (manual, one-time)

1. Install Android Studio command-line tools OR full Android Studio.
2. Set environment variables:
   - ANDROID_HOME=/path/to/android-sdk
   - ANDROID_SDK_ROOT=$ANDROID_HOME
   - PATH includes $ANDROID_HOME/cmdline-tools/latest/bin and $ANDROID_HOME/platform-tools
3. Install via sdkmanager:
   - sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
4. Verify: `adb devices` lists an emulator or USB-debugging-enabled physical device.

## Procedure: Configure Godot Android export

1. Open godot_project/ in Godot Editor.
2. Project → Export → Add → Android.
3. Set:
   - Package name: com.projectrhythm.game (or user-chosen)
   - Version code: 1 (increment per build)
   - Version name: 0.1.0
   - Icon: godot_project/assets/textures/icon.svg
   - Debug keystore: Godot default (debug APK)
   - Release keystore: user-provided (release APK — requires user approval)
   - Permissions: minimal (none required for offline MVP; add only as needed)
4. Save export preset.

## Procedure: Export an APK

From Godot Editor:
- Project → Export → Android → Export → select output .apk

From CLI (headless):
- godot --headless --export-android godot_project/ build/ProjectRhythm.apk

Debug APK for testing; release APK only after signing config and user approval.

## Procedure: Install and verify on device

1. `adb install -r build/ProjectRhythm.apk`
2. `adb shell am start -n com.projectrhythm.game/org.godotengine.godot.GodotApp` (or tap icon)
3. Verify launch, main menu, gameplay, audio, touch response.
4. `adb logcat` to inspect crashes/errors.

## Acceptance criteria

- [ ] Debug APK builds without errors
- [ ] APK installs via adb on target device
- [ ] Game launches to main menu on device
- [ ] Gameplay (touch + audio) functions on device
- [ ] Version code/name recorded in build metadata
- [ ] Release APK signed only with user approval

## Files owned

- android/ (build config)
- godot_project/project.godot (export-relevant settings — coordinate with Agent 00)
- build/ (APK output, gitignored)

## Blockers

- Android SDK not installed in current environment → see TECHNICAL_ROADMAP.md manual procedure.
