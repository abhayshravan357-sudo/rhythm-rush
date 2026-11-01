# ANDROID EXPORT PRESET — PROJECT RHYTHM (Agent 07)

Godot 4 Android export preset specification. Applied in Godot Editor: Project → Export → Add → Android.

## Preset values

| Setting | Value | Source / owner |
|---------|-------|----------------|
| Package name | com.projectrhythm.game | Agent 07 spec |
| Version code | 1 (initial) | Agent 07 versioning; bump per build |
| Version name | 0.1.0 | Matches project.godot config/version |
| Icon | res://assets/textures/icon.svg | project.godot config/icon; asset to be created by Agent 04 |
| Orientation | Handheld (sensor) | project.godot window/handheld/orientation=1 |
| Rendering method | Mobile | project.godot renderer/rendering_method="mobile" |
| Features | Mobile | project.godot config/features includes "Mobile" |
| Debug build | Enabled | Godot default debug keystore |
| Release build | Pending user approval | Release keystore not created |
| Permissions | Minimal | See below |

## Permissions (minimal)

Permission | Purpose | Required?
---|---|---
VIBRATE | Haptic feedback on note hits | Optional
WAKE_LOCK | Keep screen on during gameplay | Optional
INTERNET | None — offline-first game | No

No INTERNET permission is requested. The game operates entirely offline.

## Icon asset

- Path: res://assets/textures/icon.svg
- Format: SVG (Godot-supported vector icon)
- Status: NOT created — assets/textures/ contains only .gitkeep
- Owner: Agent 04 (UI/UX) owns godot_project/assets/textures/

## Where this is stored

Godot 4 export presets are configured in the editor and stored in the editor's export preset configuration. There is no committed export preset file in the repository yet because Godot 4 is not installed (B-01). Once installed, the preset above must be entered in Project → Export → Android and the project re-exported.

## project.godot alignment (Agent 00-owned, do not modify)

The following project.godot fields are already set and align with this preset:

- config/name="HexaRhythm"
- config/version="0.1.0"
- config/icon="res://assets/textures/icon.svg"
- window/handheld/orientation=1
- renderer/rendering_method="mobile"
- config/features=PackedStringArray("4.3", "Mobile")

Changes to project.godot require Agent 00 coordination (shared file).
