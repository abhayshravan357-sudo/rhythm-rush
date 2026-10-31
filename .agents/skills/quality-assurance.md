# Skill: Quality Assurance — Gameplay Testing, Unit Tests, Performance

Purpose: Independently verify implementation quality for PROJECT RHYTHM; Agent 06 does not author code under test.

## Scope

- Unit tests for scoring, combo, accuracy, grade
- Integration tests for audio sync, lane mapping, spawning
- Gameplay tests for touch, hold notes, simultaneous notes, miss detection
- Performance profiling (60 FPS, memory, input latency)
- Device compatibility and crash testing

## Procedure: Run a scoring unit test

1. Instantiate ScoreManager with a known noteTimeline.
2. Call reset_scoring_matrix(chart).
3. Simulate process_action_input(lane) at controlled playback times.
4. Assert rating (PERFECT/GOOD/MISS), points, combo, max_combo, accuracy.
5. Assert no negative score; combo resets on miss.
6. Assert resolved note cannot be hit twice.

## Procedure: Verify hit-window accuracy

1. Play a song with known note timestamps.
2. Tap at exact hit time → expect PERFECT (±50 ms).
3. Tap at ±100 ms → expect GOOD.
4. Tap outside window or miss → expect MISS + combo reset.
5. Confirm no tile spawns after its intended hit time.
6. Confirm audio stops on game over.
7. Repeat across Easy/Normal/Hard/Expert (when implemented).

## Procedure: Performance profiling

1. Enable Godot debug / monitor FPS during gameplay.
2. Target: 60 FPS sustained; note dips on 90/120 Hz displays.
3. Profile memory across repeated plays → should be stable (object pool).
4. Measure input latency (touch → registration) → target ≤1 frame.
5. Measure startup time → target fast (<3 s ideal).
6. Test multiple screen sizes/aspect ratios.

## Acceptance criteria

| Criterion | Target |
|-----------|--------|
| Hit-window accuracy | PERFECT ±50 ms, GOOD ±100 ms |
| Frame rate | 60 FPS stable |
| Audio sync drift | Within hit window for full song |
| Input-to-registration latency | ≤1 frame |
| Memory | No growth over repeated plays |
| Crash rate | Zero on normal playthrough |
| Device test | ≥1 physical Android device verified |

## Independence rule

Agent 06 writes tests and verifies others' code; does not implement gameplay/audio/UI features under test. Reports results to Agent 00 and logs in TASK_REGISTER.md.
