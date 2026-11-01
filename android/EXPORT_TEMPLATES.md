# EXPORT TEMPLATE REQUIREMENTS — ANDROID (Agent 07)

Godot 4 Android export templates required to build APKs.

## What are export templates

Godot uses platform-specific export templates to compile and package a project into an APK. For Android, two template variants are needed:

- Android release export template
- Android debug export template

These are downloaded/installed through the Godot Editor (Editor → Manage Export Templates) or placed manually in the Godot data directory.

## Requirements

| Template | Purpose | Required for |
|----------|---------|--------------|
| Android debug export template | Debug APK builds | Debug APK (Wave 3 T-22) |
| Android release export template | Release APK builds | Release builds (user approval) |

## Installation

Via Godot Editor:
1. Editor → Manage Export Templates
2. Download and install matching Godot version (e.g., 4.3 stable)
3. Select both debug and release Android templates

Via command line (when Godot 4 installed):
- Templates are managed through the editor; no headless command available.

## Version matching

Export templates must match the installed Godot 4 version exactly. project.godot config/features includes "4.3", so Godot 4.3.x templates are expected.

## Status

| Item | Status | Blocker |
|------|--------|---------|
| Godot 4 installed | No | B-01 |
| Export templates installed | No | B-01 (requires Godot 4) |
| Android debug template | Not available | B-01 |
| Android release template | Not available | B-01 |

Export templates cannot be installed until Godot 4 is installed (B-01).

## Build command (when unblocked)

```
godot --headless --export-android "Debug" godot_project/ build/HexaRhythm-debug.apk
```
