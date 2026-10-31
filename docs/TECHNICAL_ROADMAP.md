# TECHNICAL ROADMAP — PROJECT RHYTHM

Project: PROJECT RHYTHM
Version: 0.1
Engine: Godot 4 (ADR-001)
Platform: Android
Designated model: nemotron 3.5 super vl (free)

## Environment status

| Tool | Status | Required for |
|------|--------|--------------|
| Python 3.14.6 + pip + numpy | INSTALLED | Chart pipeline (with librosa/demucs) |
| librosa | NOT installed | Chart generation (onset/BPM detection) |
| demucs | NOT installed | Stem separation (chart pipeline) |
| Godot 4 | NOT installed | Editor, scene editing, Android export templates |
| Android SDK (command-line tools) | NOT installed | APK build, signing |
| Java JDK / Kotlin / Gradle | NOT installed | Android build toolchain |
| adb / emulator | NOT installed | Device testing, installation verification |

## Manual setup procedure (Agent 07 / user)

### 1. Install Godot 4

Download Godot 4.x (.NET or standard) from godotengine.org. Place the binary in PATH or a known location.
Verify: `godot --version`

The existing `godot_project/` opens in the Godot editor. Scenes/scripts are GDScript and editable in VS Code with the Godot extension.

### 2. Install Android SDK

- Install Android Studio OR the Android command-line tools.
- Set ANDROID_HOME / ANDROID_SDK_ROOT.
- Install platform-tools (adb), build-tools, and an Android platform (e.g., android-34).
- Verify: `adb devices` (emulator or physical device with USB debugging enabled).

### 3. Install Python chart dependencies

`pip install librosa demucs numpy`

Requires ffmpeg for demucs. Verify chart pipeline:
`python3 pipeline/generate_chart.py <audio.mp3>`

### 4. Configure Godot Android export

In Godot Editor: Project → Export → add Android preset. Set:
- Debug keystore (for debug APK)
- Release keystore + signing config (for release APK — user approval required)
- Custom icon / package name (e.g., com.projectrhythm.game)
- Version code / version name

### 5. Export APK

From Godot Editor or command line:
`godot --headless --export-android godot_project/ build/output.apk`

Agent 07 owns build automation, versioning, and release documentation.

## Wave schedule

| Wave | Focus | Exit criteria |
|------|-------|---------------|
| Wave 1 Discovery | Environment audit | Complete (this document) |
| Wave 2 Architecture & Design | GDD, ADR, prompts, skills, org | Agent 00 + user approval |
| Wave 3 Playable MVP | Menu, one song, 4-lane, sync, scoring, results, APK | Works on real Android device |
| Wave 4 Core Expansion | Multiple songs, difficulties, hold/simultaneous notes, previews, progression | Stable gameplay |
| Wave 5 Advanced Systems | Endless/Rush/Challenge, achievements, daily rewards, customization | Feature complete |
| Wave 6 Production | Testing, profiling, device compat, release build | Release-ready APK |
| Wave 7 Future | Multiplayer, leaderboards, cloud, licensed music | Post-launch |

## Blockers

- B-01: Godot 4 not installed (blocks editor work and Android export)
- B-02: Android SDK not installed (blocks APK generation)
- B-03: librosa/demucs not installed (blocks chart pipeline regeneration)
- B-04: No Android device/emulator (blocks device testing T-23)
