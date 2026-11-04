# ANDROID EXPORT PRESET — RELEASE CONFIGURATION — PROJECT RHYTHM (Agent 07)

Extends android/EXPORT_PRESET.md with release build configuration details.

## Release Preset Configuration

Release builds require a release keystore and signing configuration. All
keystore creation, alias generation, and signing occur only after explicit
user approval. Keystore files and passwords are NEVER committed to the repo.

| Setting | Release Value | Notes |
|---------|---------------|-------|
| Package name | com.projectrhythm.game | Same as debug |
| Version code | 2 (initial release) | Bumped per release build |
| Version name | 1.0.0 | Semantic versioning |
| Orientation | Handheld (sensor) | Same as debug |
| Rendering method | Mobile | Same as debug |
| Features | Mobile | Same as debug |
| Debug build | Disabled | Release uses release keystore |
| Release build | Enabled (pending user approval) | Keystore not created |
| Permissions | Minimal | VIBRATE (optional), WAKE_LOCK (optional), no INTERNET |

## Release Keystore (placeholder — not created without user approval)

| Field | Value | Source |
|-------|-------|--------|
| Keystore path | user-provided | Never committed |
| Keystore alias | user-provided | Never committed |
| Store password | user-provided | Never committed |
| Key password | user-provided | Never committed |

## Release build flow

1. User approves release signing and provides keystore details.
2. Agent 07 creates keystore + alias (after approval only).
3. Export preset configured with release signing config in Godot Editor.
4. `godot --headless --export-android "Release" godot_project/ build/HexaRhythm-release.apk`
5. Agent 00 reviews build config and APK.
6. User sign-off before distribution.

## Permissions

| Permission | Purpose | Required? |
|------------|---------|-----------|
| VIBRATE | Haptic feedback on note hits | Optional |
| WAKE_LOCK | Keep screen on during gameplay | Optional |
| INTERNET | None — offline-first game | No |

No INTERNET permission is requested. The game operates entirely offline.

## Icons

| Variant | Path | Status |
|---------|------|--------|
| Main (192px) | res://assets/textures/icon.svg | NOT created — Agent 04-owned |
| Adaptive foreground (432px) | res://assets/textures/icon.svg | NOT created |
| Adaptive background (432px) | res://assets/textures/icon.svg | NOT created |

## Where configuration lives

- `godot_project/export_presets.cfg` — committed export preset config (debug)
- `android/EXPORT_PRESET.md` — this document (documentation only)
- `android/RELEASE_SIGNING.md` — release signing procedures (placeholder)
- `godot_project/project.godot` — package name, version, icon, orientation, rendering (Agent 00-owned)

Release signing keys and passwords are never stored in version control.