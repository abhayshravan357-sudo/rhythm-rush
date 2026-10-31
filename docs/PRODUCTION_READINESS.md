# PRODUCTION READINESS — PROJECT RHYTHM

Project: PROJECT RHYTHM
Owner: Agent 00 (Chief Engineer) with Agent 07 (Release)

## Release readiness checklist

| Item | Status | Owner | Notes |
|------|--------|-------|-------|
| Core gameplay functional (4 lanes, sync, scoring) | Pending | Agent 02/03 | Wave 3 |
| One playable song with licensed/original audio | Pending | Agent 03 | Copyright audit first |
| Android debug APK builds cleanly | Pending | Agent 07 | Requires Android SDK |
| APK installs and runs on physical device | Pending | Agent 06/07 | Requires device |
| Audio latency calibration works | Pending | Agent 03 | OffsetCalibration |
| Hit windows calibrated (PERFECT/GOOD/MISS) | Pending | Agent 06 | ±50/±100 ms target |
| 60 FPS on target device | Pending | Agent 06 | Profiling |
| Music asset registry complete | Pending | Agent 03 | All tracks licensed |
| No hardcoded secrets | Pending | Agent 00 | Security review |
| Local data storage safe | Pending | Agent 05 | user:// persistence |
| Versioning scheme defined | Pending | Agent 07 | SemVer + build code |
| Release build signed | Pending | Agent 07 | User approval required |
| Release notes written | Pending | Agent 07 | RELEASE_NOTES.md |

## Security & governance

- No hardcoded secrets or keys
- Appropriate Android permissions only (minimal)
- Safe local data storage (user://)
- Input validation on touch/chart data
- Dependency vulnerability checks where applicable
- Reproducible builds where practical

## Approvals required (user mandatory)

- Destructive Git operations
- Major architecture changes
- Production deployment
- Signing and release operations
- External service integration
- Purchases / financial functionality

## Definition of release-ready

Debug APK installable on device, full MVP playable offline, scoring accurate, audio synced, no crashes, documented. Release APK only after user sign-off.
