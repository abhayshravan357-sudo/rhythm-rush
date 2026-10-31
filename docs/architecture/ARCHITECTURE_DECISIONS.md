# ARCHITECTURE DECISION RECORD — PROJECT RHYTHM

Project: PROJECT RHYTHM
ADR ID: ADR-001
Status: Proposed (pending Agent 00 approval)
Model: nemotron 3.5 super vl (free)

## Decision

Select Godot 4 as the game engine and runtime for PROJECT RHYTHM, targeting Android export and APK generation.

## Context

The project requires a 2D rhythm game with:
- Accurate music synchronization (authoritative audio clock, not frame delta)
- Responsive touch input (4+ lanes, multi-touch safe)
- Smooth 60 FPS tile animations
- Offline gameplay
- Android APK generation and release preparation

An existing Godot 4 project foundation is already present in the repository (`godot_project/`), including:
- `project.godot` configured for mobile renderer, handheld orientation, canvas_items stretch
- Autoloads: ChartLoader, AudioSync, ScoreManager, OffsetCalibration
- Scenes: MainMenu, GameScene, CalibrationScene
- Scripts: LaneManager, NoteSpawner (object pool), AudioSync (hardware-clock sync), ScoreManager (hit windows/combo), OffsetCalibration (latency calibration)
- A Python chart-generation pipeline (`pipeline/`) producing JSON charts compatible with ChartLoader

## Alternatives considered

| Option | Fit for rhythm game | Android APK | Touch latency | Audio sync | Maintainability | Build size | AI coding support |
|--------|---------------------|-------------|---------------|------------|-----------------|------------|-------------------|
| Godot 4 (selected) | High — 2D, _process/_physics_process, AudioServer clock | Good — official Android export templates | Good | Excellent — get_playback_position + get_time_since_last_mix | High — GDScript, scene/node composition | Moderate | Strong |
| Unity | High | Good | Good | Good | High | Large | Strong |
| Native Android (Kotlin + custom view) | Moderate — must build engine | Excellent | Excellent | Good (AudioTrack timestamp) | Moderate — more boilerplate | Small | Moderate |

## Rationale

- **Godot 4** is already the incumbent: a working 6-lane rhythm foundation exists, including an audio-clock synchronization design (AudioSync.gd) that matches the master-prompt requirement for an authoritative audio clock.
- The existing pipeline (`pipeline/`) emits JSON charts that ChartLoader.gd already consumes, giving an immediate note-event system.
- Godot's AudioServer hardware clock (`get_playback_position` + `get_time_since_last_mix`) directly addresses timing-drift risk called out in the master prompt.
- GDScript and scene/node composition are maintainable by AI agents and match the "clean code" skill.
- Android export via official export templates produces APKs; build automation is handled by Agent 07.

## Known risks / mitigations

| Risk | Mitigation |
|------|------------|
| Godot 4 not installed in this environment | Manual install procedure documented in TECHNICAL_ROADMAP.md; Agent 07 owns Android export setup |
| Android audio latency | OffsetCalibration.gd provides user-offset persistence; AudioSync applies it to adjusted_system_time |
| Audio synchronization drift | Timing driven by AudioServer hardware clock, not accumulated frame delta |
| APK signing / release | Agent 07 handles signing preparation; user approval required for release/signing |

## Consequences

- Source language: GDScript (Godot 4.x)
- Export target: Android (APK)
- Chart format: JSON (schema defined by charts/example_chart.json + ChartLoader.gd)
- Audio: OGG Vorbis recommended; original/public-domain/licensed tracks only
- Existing 6-lane foundation will be adapted to 4-lane MVP per Game Design Document (lane count is configurable)

## Approval

Requires Agent 00 (Chief Engineer) approval and user acknowledgment before implementation proceeds beyond Wave 2.
