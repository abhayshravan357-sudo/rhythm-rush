# ANDROID BUILD READINESS — PROJECT RHYTHM (Agent 07)

Project: PROJECT RHYTHM
Owner: Agent 07 (Android & Release Engineer)
Branch: agent/project-rhythm-android
Worktree: /home/abhaysawant/project-rhythm-android
Platform: Android
Engine: Godot 4 (ADR-001)

## Status summary

Environment is blocked; no APK can be generated until the toolchain is installed. All configuration is documented and ready to apply once unblocked.

| Item | Status | Blocker | Source |
|------|--------|---------|--------|
| Android export preset configuration | Documented (pending editor apply) | B-01, B-02 | android/EXPORT_PRESET.md |
| Debug APK build path | Documented (not executable) | B-01 (Godot 4), B-02 (Android SDK) | android/BUILD_READINESS.md |
| Version code/name tracking | Defined | None (documentation only) | android/VERSIONING.md |
| Release signing prep | Documented | User approval mandatory | android/RELEASE_SIGNING.md |
| Export templates | Documented | B-01 (Godot 4) | android/EXPORT_TEMPLATES.md |
| Device testing (T-23) | Not possible | B-01, B-02, B-04 | docs/TECHNICAL_ROADMAP.md |

**Overall: BLOCKED.** No debug or release APK can be generated until Godot 4 and the Android SDK are installed. All configuration is documented and ready to apply once the toolchain is present.

## Export preset (desired, not yet applied)

Defined in android/EXPORT_PRESET.md. Applied in Godot Editor: Project → Export → Add → Android.

| Setting | Value |
|---------|-------|
| Package name | com.projectrhythm.game |
| Version code | 1 (initial), bumped per build |
| Version name | 0.1.0 |
| Icon | res://assets/textures/icon.svg (asset not yet created; Agent 04-owned) |
| Orientation | Handheld (sensor) |
| Rendering method | Mobile |
| Features | Mobile |
| Debug build | Enabled (Godot default debug keystore) |
| Release build | Pending user approval |
| Permissions | Minimal — VIBRATE (optional), WAKE_LOCK (optional); no INTERNET |

project.godot alignment (Agent 00-owned, do not modify):
- config/name="HexaRhythm", config/version="0.1.0"
- config/icon="res://assets/textures/icon.svg"
- window/handheld/orientation=1
- renderer/rendering_method="mobile"
- config/features includes "Mobile"

Changes to project.godot require Agent 00 coordination.

## Build path (blocked)

Once Godot 4 and Android SDK are installed:

```
godot --headless --export-android "Debug" godot_project/ build/HexaRhythm-debug.apk
adb install build/HexaRhythm-debug.apk
```

Output: `build/HexaRhythm-debug.apk`. This is Wave 3 deliverable T-22.

## Release signing (pending user approval)

Defined in android/RELEASE_SIGNING.md. No keystore creation, alias generation, or signing occurs without explicit user approval. Keystore artifacts and passwords are never committed to the repository.

Release build flow:
1. User approves release signing and keystore details.
2. Agent 07 creates keystore + alias (after approval only).
3. Export preset configured with release signing config.
4. `godot --headless --export-android "Release" godot_project/ build/HexaRhythm-release.apk`
5. Submit to Agent 00 for review; user sign-off before distribution.

## Documented blockers

| ID | Blocker | Owner | Resolution |
|----|---------|-------|------------|
| B-01 | Godot 4 not installed | Agent 07 / user | Manual install; required for editor work and Android export |
| B-02 | Android SDK not installed | Agent 07 / user | Manual install; required for APK generation |
| B-04 | No Android device/emulator | user | Required for T-23 device testing |

See docs/TECHNICAL_ROADMAP.md section "Manual setup procedure (Agent 07 / user)" for install steps.

## Cross-ownership notes

- project.godot (Android-export-relevant fields) is owned by Agent 00; changes require Agent 00 coordination.
- docs/TECHNICAL_ROADMAP.md is owned by Agent 00; blocker/status updates require Agent 00 coordination.
- godot_project/assets/textures/icon.svg owned by Agent 04 (UI/UX).
- All release/signing/production deployment require explicit user approval.
- Do not merge independently; submit build config to Agent 00 for review.

## Next actions (unblocked when SDK present)

1. Agent 00 approves project.godot / export preset changes.
2. User installs Godot 4 + Android SDK (manual procedure in docs/TECHNICAL_ROADMAP.md).
3. Apply Android export preset in Godot Editor (package, version, icon, keystore, permissions).
4. Generate debug APK (Wave 3 T-22).
5. Submit build config to Agent 00 for review.
