# RELEASE SIGNING PREPARATION — ANDROID (Agent 07)

Release signing documentation for Project Rhythm. No release/signing action is taken without explicit user approval.

## Governance

- Release APK signing requires explicit user approval before any keystore creation, alias generation, or signing operation.
- Debug APKs use Godot's default debug keystore (no user approval needed).
- Do not hardcode keystore passwords or alias credentials in the repository.
- All signing artifacts are outside code ownership and must be handled per user direction.

## Keystore (not yet created)

| Item | Value | Status |
|------|-------|--------|
| Keystore path | TBD | Not created |
| Keystore format | JKS (recommended) | Pending |
| Alias | TBD | Pending |
| Validity | 25+ years | Pending |
| Passwords | Not stored in repo | N/A |

Keystore creation is blocked pending user approval (release/signing constraint).

## Debug keystore

Godot auto-generates a debug keystore for debug APKs. No manual keystore is needed for debug builds.

## Release build flow (pending approval)

1. User approves release signing and provides/approves keystore details.
2. Agent 07 creates keystore + alias (only after approval).
3. Android export preset configured with release signing config.
4. `godot --headless --export-android "Release" godot_project/ build/HexaRhythm-release.apk`
5. APK signed with release keystore + alias.
6. Submit to Agent 00 for review; user sign-off before distribution.

## No secrets in repository

- Keystore files (*.keystore, *.jks) must NOT be committed.
- Passwords and key alias credentials must NOT be committed.
- signing config references (paths only, no secrets) may be documented here.

## Related

- PRODUCTION_READINESS.md: "Release build signed — Pending — Agent 07 — User approval required"
- RISK_REGISTER.md R-08: "APK signing/release mishandled — Signing prep only; user mandatory approval for release/signing"
