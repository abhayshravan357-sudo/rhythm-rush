# POP!_OS REPRODUCIBLE SETUP GUIDE — HEXARHYTHM

**Platform:** Pop!_OS Linux 22.04 LTS / Ubuntu-based (x86_64)  
**Target Engine:** Godot 4.3  
**Target JDK:** OpenJDK 17 (Temurin)  
**Target SDK:** Android API Level 34 (Android 14)  
**Target Python:** Python 3.14.6 via `uv`

---

## 1. Quick Verification Commands

Run these commands to verify that your environment is fully operational:

```bash
# 1. Verify Godot Engine
godot --version
# Expected: 4.3.stable.official.77dcf97d8

# 2. Verify Godot Export Templates
ls -la ~/.local/share/godot/export_templates/4.3.stable/
# Expected: android_debug.apk, android_release.apk, version.txt

# 3. Verify Java JDK 17
java -version
# Expected: openjdk version "17.0.21"

# 4. Verify Android SDK tools
export JAVA_HOME=~/.local/share/jdk-17
sdkmanager --version
# Expected: 12.0

# 5. Verify Python Pipeline & Unit Tests
.venv/bin/pytest tests/
# Expected: 141 passed

# 6. Verify Godot Runtime Smoke Tests
godot --headless --path godot_project "res://scenes/RuntimeSmokeTest.tscn"
# Expected: 23 / 23 PASSED (0 FAILED)
```

---

## 2. User-Local Toolchain Installation (No Sudo Required)

All installations are isolated to user space (`~/.local/`) and are 100% reversible by deleting the corresponding directories.

### A. Godot Engine 4.3 Stable

```bash
# Download and install binary
curl -L -o /tmp/godot4.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
unzip -q /tmp/godot4.zip -d ~/.local/bin/
rm /tmp/godot4.zip
chmod +x ~/.local/bin/Godot_v4.3-stable_linux.x86_64
ln -sf ~/.local/bin/Godot_v4.3-stable_linux.x86_64 ~/.local/bin/godot
ln -sf ~/.local/bin/Godot_v4.3-stable_linux.x86_64 ~/.local/bin/godot4

# Download and install export templates
mkdir -p ~/.local/share/godot/export_templates/4.3.stable
curl -L -o /tmp/export_templates.tpz https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
unzip -q /tmp/export_templates.tpz -d /tmp/templates_extracted
mv /tmp/templates_extracted/templates/* ~/.local/share/godot/export_templates/4.3.stable/
rm -rf /tmp/templates_extracted /tmp/export_templates.tpz
```

### B. Java JDK 17 (Eclipse Temurin)

```bash
mkdir -p ~/.local/share/jdk-17
curl -L -o /tmp/jdk17.tar.gz "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.21%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.21_9.tar.gz"
tar -xzf /tmp/jdk17.tar.gz -C ~/.local/share/jdk-17 --strip-components=1
rm /tmp/jdk17.tar.gz
ln -sf ~/.local/share/jdk-17/bin/java ~/.local/bin/java
ln -sf ~/.local/share/jdk-17/bin/javac ~/.local/bin/javac
ln -sf ~/.local/share/jdk-17/bin/keytool ~/.local/bin/keytool
```

### C. Android Command-Line Tools & Keystore

```bash
# Android SDK cmdline-tools
mkdir -p ~/.local/share/android-sdk/cmdline-tools
curl -L -o /tmp/cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline_extracted
mv /tmp/cmdline_extracted/cmdline-tools ~/.local/share/android-sdk/cmdline-tools/latest
rm -rf /tmp/cmdline-tools.zip /tmp/cmdline_extracted
ln -sf ~/.local/share/android-sdk/cmdline-tools/latest/bin/sdkmanager ~/.local/bin/sdkmanager
ln -sf ~/.local/share/android-sdk/cmdline-tools/latest/bin/avdmanager ~/.local/bin/avdmanager

# Debug Keystore
mkdir -p ~/.local/share/godot/keystores
keytool -genkey -v -keystore ~/.local/share/godot/keystores/debug.keystore \
  -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
```

### D. Python Chart-Generation Virtual Environment

```bash
# Create virtual environment and install dependencies
uv venv
uv pip install -r requirements.txt
```

---

## 3. Environment Variables Configuration

Add the following to your `~/.bashrc` or local session environment:

```bash
export PATH="$HOME/.local/bin:$PATH"
export JAVA_HOME="$HOME/.local/share/jdk-17"
export ANDROID_HOME="$HOME/.local/share/android-sdk"
export ANDROID_SDK_ROOT="$HOME/.local/share/android-sdk"
```

---

## 4. Android SDK Package Completion (User Approval Required)

To complete the Android export toolchain, accept the Android SDK licenses and install the required build packages:

```bash
export JAVA_HOME=~/.local/share/jdk-17
export ANDROID_HOME=~/.local/share/android-sdk

# Accept Android SDK licenses
yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses

# Install build tools and platform packages
sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "build-tools;34.0.0" "platforms;android-34"
```

Once installed, Godot can export the debug APK headlessly:

```bash
godot --headless --path godot_project --export-debug "Android" build/HexaRhythm-debug.apk
```

