# ENVIRONMENT AUDIT REPORT — HEXARHYTHM

**Date:** 2026-11-02  
**Coordinator:** Agent 00 (Chief Engineer & Integration Coordinator)  
**Host Platform:** Pop!_OS Linux (x86_64)  
**Milestone:** Environment Setup & Runtime Readiness

---

## 1. Executive Summary

This audit assesses the actual development environment, tools, engine runtimes, SDKs, and dependencies for HexaRhythm. Prior reports noted blockers B-01 (missing Godot 4), B-02 (missing Android SDK), B-03 (missing audio dependencies), and B-04 (no device/emulator).

Through reversible, user-local installations and targeted defect resolutions:
- **Godot 4.3**: Installed, configured, verified, and active (`~/.local/bin/godot`).
- **Export Templates**: Godot 4.3 stable templates installed (`~/.local/share/godot/export_templates/4.3.stable/`).
- **JDK 17**: Eclipse Temurin OpenJDK 17.0.21 installed and verified (`~/.local/share/jdk-17`).
- **Android SDK Command-Line Tools**: cmdline-tools 12.0 installed (`~/.local/share/android-sdk/cmdline-tools/latest`).
- **Python Pipeline**: Isolated virtual environment created (`.venv`) with Python 3.14.6; `librosa`, `numpy`, `scipy`, `soundfile`, `matplotlib`, and `pytest` installed.
- **Python Regression**: 141 of 141 tests PASS (0.18s).
- **Godot Runtime Smoke Test**: 23 of 23 validation steps PASS in real headless engine execution.
- **Android Export Preset**: `export_presets.cfg` created; debug keystore configured; full APK export awaits sdkmanager package installation (licenses).

---

## 2. Toolchain Inventory

| Tool / Component | Version Detected | Installed Path | Status |
|------------------|------------------|----------------|--------|
| **OS** | Pop!_OS Linux 22.04 LTS | Linux 6.9.3-76060903-generic x86_64 | Verified |
| **Godot Engine** | 4.3.stable.official.77dcf97d8 | `/home/abhaysawant/.local/bin/godot` | PASS |
| **Godot Export Templates** | 4.3.stable (Android, Linux, Web, Windows) | `/home/abhaysawant/.local/share/godot/export_templates/4.3.stable/` | PASS |
| **Java JDK** | OpenJDK Temurin 17.0.21+9 (64-Bit) | `/home/abhaysawant/.local/share/jdk-17` | PASS |
| **Android SDK cmdline-tools** | 12.0 (Google official) | `/home/abhaysawant/.local/share/android-sdk/cmdline-tools/latest` | PASS |
| **Android Debug Keystore** | 2048-bit RSA, valid 10,000 days | `/home/abhaysawant/.local/share/godot/keystores/debug.keystore` | PASS |
| **Python Runtime** | CPython 3.14.6 / CPython 3.12.3 | `/home/abhaysawant/anaconda3/bin/python`, `/usr/bin/python3` | PASS |
| **Python Package Manager** | uv 0.13.6 | `/home/abhaysawant/.local/bin/uv` | PASS |
| **Virtual Environment** | Python 3.14.6 `.venv` | `/home/abhaysawant/hexa-rhythm/.venv` | PASS |
| **Audio DSP Libs** | librosa 1.0.0, soundfile 0.14.0, scipy 1.18.1, numpy 2.5.4 | Installed in `.venv` | PASS |
| **Test Runner** | pytest 9.2.0 | `.venv/bin/pytest` | PASS (141/141) |
| **Android Devices / Emulators** | None connected | adb devices | BLOCKED (B-04) |

---

## 3. Compatibility Findings

1. **Godot 4.3 GDScript API Compatibility:**
   - GDScript 4 parser strictly forbids autoload singletons from declaring `class_name` matching their autoload identifier (`GameConfig.gd`, `PlayerProfile.gd`).
   - Constant arrays in GDScript 4 cannot use constructor syntax like `PackedInt32Array([4, 6])`; standard typed arrays (`Array[int] = [4, 6]`) are required.
   - Signal declarations cannot share identical names with member functions (`signal game_over` vs `func game_over`).
   - Python-style floor division `//` does not exist in GDScript; integer division `/` is standard.
   - `round()` in GDScript 4 takes a single argument (unlike Python `round(val, ndigits)`); `snapped(val, step)` or string formatting is standard.
   - Signal parameter counts must match connectee signatures (`alignment_processed` emitted 3 parameters, but `_on_hit_evaluated` declared 2).

2. **Scene Tree Hierarchies:**
   - `SongSelectionUI.gd` was calling `get_parent().get_node("VBox/...")` despite being attached directly to root node `SongSelection`.
   - `GameScene.tscn` had `PauseOverlay/VBox` children pointing to nonexistent `./VBox` parent paths, and `JudgmentLine` was misplaced inside `LaneManager` rather than root `GameScene`.

3. **Audio-to-Chart Pipeline Compatibility:**
   - Heavy neural-network stem separation (`demucs`) requires multi-gigabyte PyTorch and CUDA dependencies.
   - The pipeline orchestrator `pipeline/generate_chart.py` was refined to provide clean, deterministic fallback to direct full-mix transient analysis whenever Demucs is unavailable.
   - Generated chart `charts/example_track_chart.json` successfully loads into Godot `ChartLoader`.

---

## 4. Blocker Log Status

| ID | Description | Historical Status | Current Status | Resolution / Action Required |
|----|-------------|-------------------|----------------|------------------------------|
| **B-01** | Godot 4 not installed | BLOCKED | **RESOLVED** | Installed Godot 4.3 stable binary and export templates to `~/.local/`. Verified via real execution. |
| **B-02** | Android SDK not installed | BLOCKED | **PARTIALLY RESOLVED** | OpenJDK 17 and Android cmdline-tools 12.0 installed. Debug keystore and export presets configured. SDK packages (`platform-tools`, `build-tools;34.0.0`) await license acceptance. |
| **B-03** | Python audio dependencies missing | BLOCKED | **RESOLVED** | `.venv` created with `librosa`, `soundfile`, `scipy`, `numpy`. Pipeline generates 4-lane charts from `.ogg` audio. Demucs isolated as optional. |
| **B-04** | No Android device / emulator | BLOCKED | **BLOCKED** | External hardware dependency. Physical device or emulator setup required for L5/L6 testing. |

