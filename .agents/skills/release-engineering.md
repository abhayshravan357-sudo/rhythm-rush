# Skill: Release Engineering — APK Generation, Signing, Versioning

Purpose: Produce installable Android APKs for PROJECT RHYTHM, manage versioning, and prepare release documentation.

## Scope

- Debug and release APK generation via Godot Android export
- Keystore creation and signing configuration
- Version code / version name management (semantic)
- Build automation and reproducibility
- Release documentation and installation instructions

## Procedure: Version a build

- Use semantic versioning: MAJOR.MINOR.PATCH (e.g., 0.1.0).
- Version code: integer, increment for every build uploaded to a device/store.
- Record in godot_project export preset and in build metadata.
- Update RELEASE_NOTES.md per version.

## Procedure: Generate a debug APK

1. Confirm Android SDK installed (ANDROID_HOME set; adb works).
2. Godot export preset Android → debug keystore configured.
3. `godot --headless --export-android godot_project/ build/ProjectRhythm-debug.apk`
4. `adb install -r build/ProjectRhythm-debug.apk`
5. Launch and verify main menu + gameplay on device.

## Procedure: Prepare a release APK (user approval required)

1. User provides release keystore or approves creation.
2. Configure release signing in Godot export preset (keystore path, key alias, passwords — never hardcode in repo; use env/secure input).
3. `godot --headless --export-android godot_project/ build/ProjectRhythm-release.apk`
4. Verify signed APK: `apksigner verify --verbose build/ProjectRhythm-release.apk` (if build-tools available).
5. Document version, date, changelog in RELEASE_NOTES.md.
6. User must explicitly approve production deployment/signing.

## Acceptance criteria

- [ ] Debug APK builds cleanly and installs via adb
- [ ] Release APK signed (only after user approval)
- [ ] Version code/name tracked and bumped per build
- [ ] Installation instructions documented
- [ ] Release notes present per version
- [ ] No secrets committed to repository

## Files owned

- android/ (build config, signing templates)
- build/ (APK output — gitignored)
- docs/RELEASE_NOTES.md
- godot_project/project.godot (version fields — coordinate Agent 00)

## Blocker

- Android SDK not installed → TECHNICAL_ROADMAP.md manual procedure.
