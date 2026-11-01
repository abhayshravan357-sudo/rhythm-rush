# VERSIONING — ANDROID BUILD (Agent 07)

Semantic version tracking for Project Rhythm Android builds.

## Version scheme

| Field | Format | Example | Source |
|-------|--------|---------|--------|
| Version name | SemVer (MAJOR.MINOR.PATCH) | 0.1.0 | project.godot config/version |
| Version code | Positive integer | 1 | Android export preset, bumped per build |

## Relationship

- Version name (0.1.0) is the human-readable semantic version, stored in project.godot `config/version`.
- Version code (1) is the Android-internal build code, stored in the Android export preset. It must strictly increase with every uploadable build.
- Initial: version code = 1, version name = 0.1.0.

## Bump per build

Every new build (debug or release candidate) must increment the version code:

| Build | Version code | Version name |
|-------|-------------|--------------|
| Initial debug | 1 | 0.1.0 |
| Next debug build | 2 | 0.1.0 |
| Release candidate 1 | 3 | 0.1.0-rc1 |
| Release 1.0 | 4 | 1.0.0 |

The version code bump is recorded in this file's build log below.

## Build log

| # | Date (UTC) | Version code | Version name | Build type | Notes |
|---|------------|-------------|--------------|------------|-------|
| — | — | — | — | — | No builds yet (blocked by B-01, B-02) |

## Maintenance

- Agent 07 owns version code/name tracking.
- Bump version code before every export.
- Sync version name with project.godot config/version when it changes (Agent 00 coordination for project.godot).
- Record each build in the build log above.
