# RISK REGISTER — PROJECT RHYTHM

| ID | Risk | Likelihood | Impact | Owner | Mitigation / Owner action |
|----|------|------------|--------|-------|---------------------------|
| R-01 | Audio latency / timing drift on Android | High | High | Agent 03 + Agent 07 | Use AudioServer hardware clock (not frame delta); user offset calibration; QA verifies hit windows on device |
| R-02 | Android SDK / Godot not installed in env | High | High | Agent 07 / user | Manual install procedure (TECHNICAL_ROADMAP.md); user approval before install |
| R-03 | Copyrighted music/IP used inadvertently | Medium | High | Agent 03 / Agent 00 | Music asset registry; original/public-domain/licensed audio only; audit before release |
| R-04 | Multi-touch / duplicate hit scoring bugs | Medium | Medium | Agent 02 + Agent 06 | Lane-resolved input; resolved_flags per note; unit tests for hit registration |
| R-05 | No Android device for testing | High | Medium | user | Provide physical device or emulator; QA signs off only after device verification |
| R-06 | Specialist worktree conflicts / lost work | Low | Medium | Agent 00 | Dedicated branches/worktrees; no independent merges; integration via Agent 00 |
| R-07 | Performance below 60 FPS | Medium | Medium | Agent 06 | Object pooling (NoteSpawner); mobile renderer; profiling on target devices |
| R-08 | APK signing/release mishandled | Low | High | Agent 07 / user | Signing prep only; user mandatory approval for release/signing |
| R-09 | Chart/audio desync after latency calibration | Medium | Medium | Agent 03 | OffsetCalibration persists user_offset; AudioSync applies on every frame |
| R-10 | Scope creep (multiplayer/online too early) | Medium | Medium | Agent 00 | Wave-gated roadmap; online features deferred to Wave 7 |

## Review cadence

Risk register reviewed at the start of each wave by Agent 00. High/High risks require explicit mitigation before proceeding.
