# STEP 5 — Technology Selection Recommendation

**Date:** 2026-10-31  
**Selected Engine:** Godot 4

## Comparison

| Criteria | Godot 4 (SELECTED) | Unity | Native Android (Kotlin) |
|----------|-------------------|-------|-------------------------|
| 2D Rhythm Game Fit | Excellent - Node2D, _process, easy animations | Good | Poor - must build engine from scratch |
| Touch Responsiveness | Good - direct input handling | Good | Excellent |
| Audio Synchronization | Excellent - AudioServer.get_playback_position() + get_time_since_last_mix() | Good | Good (AudioTrack) but more manual work |
| Android APK Export | Good - official Android export templates | Good | Native (best) |
| Development Speed | Fast - scene system, GDScript, existing project | Moderate | Slow - boilerplate heavy |
| Build Size | Moderate | Large | Small |
| Learning Curve | Moderate (GDScript) | Steep | Steep for game engine work |
| AI Coding Support | Strong - GDScript is simple | Strong | Moderate |
| Existing Foundation | **YES** - Full working project exists in repo | No | No |

## Rationale

1. **Existing foundation exists** - `godot_project/` contains a working 6-lane rhythm game with all core systems implemented
2. **Audio timing is correct** - `AudioSync.gd` already uses authoritative hardware clock (AudioServer), exactly as required
3. **Object pooling implemented** - `NoteSpawner.gd` prevents GC pauses during gameplay
4. **Chart pipeline compatible** - Python pipeline generates JSON charts consumed by `ChartLoader.gd`
5. **Mobile-optimized** - `project.godot` configured with mobile renderer, handheld orientation
6. **Fast to extend** - MVP only needs to adapt 6-lane to 4-lane and polish existing systems

## Recommendation

**Use Godot 4** as the engine. The existing codebase is production-quality foundation that would take weeks to replicate in Unity or months in native Kotlin. Focus efforts on extending rather than rebuilding.

See `docs/architecture/ARCHITECTURE_DECISIONS.md` for full ADR-001.
