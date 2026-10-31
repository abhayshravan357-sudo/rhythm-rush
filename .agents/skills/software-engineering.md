# Skill: Software Engineering — Clean Code, Debugging, Refactoring, Architecture

Purpose: Maintain code quality, debuggability, and maintainable architecture across all PROJECT RHYTHM agents.

## Scope

- GDScript and Python clean-code conventions
- Debugging workflow (Godot debugger, print, assert)
- Refactoring with tests in place
- Architecture patterns: singleton autoloads, object pool, state machine, separation of game logic from view
- Code review standards

## Procedure: Debug a gameplay timing issue

1. Reproduce on device or editor with visible hit-window debug overlay.
2. Log AudioSync.adjusted_system_time at touch and at note timestamp.
3. Compare delta against hit-window thresholds (±50/±100 ms).
4. Check for frame-delta accumulation (should not be used for note timing).
5. Verify resolved_flags prevents duplicate hits.
6. Fix in owning agent's worktree; submit to Agent 00 for integration.

## Procedure: Refactor safely

1. Ensure the affected area has unit/integration tests passing (Agent 06).
2. Make the change in the agent worktree branch.
3. Run existing tests; confirm no regression.
4. Request Agent 00 integration review before merging to master.

## Architecture conventions

- Game logic separate from visual representation (ScoreManager has no scene nodes; NoteSpawner only draws).
- Autoload singletons for global systems (AudioSync, ChartLoader, ScoreManager, OffsetCalibration).
- Object pool for per-frame visuals (NoteSpawner) to avoid GC pauses.
- Viewport-relative layout (LaneManager computes column_width_step from viewport size).
- Configurable constants at top of scripts (APPROACH_TIME, hit windows, lane_count).

## Acceptance criteria

- [ ] No magic numbers in gameplay logic; constants named and documented
- [ ] Game logic testable without a scene (singletons separable)
- [ ] Every agent change has an associated test or verification step
- [ ] Code review by Agent 00 before integration to master
- [ ] No committed debug-only code left in production branches
