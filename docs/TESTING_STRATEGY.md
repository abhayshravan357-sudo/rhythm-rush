# TESTING STRATEGY — PROJECT RHYTHM

Project: PROJECT RHYTHM
Owner: Agent 06 (QA & Performance Engineer)
Model: nemotron 3.5 super vl (free)

## Test levels

### Unit tests (tests/unit/)
- Scoring hit-window evaluation (PERFECT/GOOD/MISS boundaries)
- Combo counter and max-combo updates
- Accuracy percentage calculation
- Grade calculation
- Negative-score prevention
- Chart loading/validation (ChartLoader)

### Integration tests (tests/integration/)
- AudioSync hardware-clock time vs. note timestamps
- LaneManager touch-to-lane mapping
- NoteSpawner object pool spawn/retire
- ScoreManager + LaneManager + AudioSync integration
- Pause/resume synchronization

### Gameplay tests (tests/gameplay/)
- Touch detection on each of 4 lanes
- Hold-note start/release tracking
- Simultaneous multi-lane notes
- Miss detection (note drifts past window without hit)
- Tiles never spawn after intended hit time
- Audio stops on game over

### Device / performance tests
- 60 FPS sustained gameplay on target devices
- Input latency (touch → hit registration)
- Audio synchronization accuracy (±hit window)
- Memory stability across a full song
- Startup time
- Screen size / aspect ratio handling
- Battery efficiency sample

## Acceptance criteria

| Criterion | Target |
|-----------|--------|
| Hit-window accuracy | PERFECT ±50 ms, GOOD ±100 ms (calibrated) |
| Frame rate | 60 FPS stable during gameplay |
| Audio sync drift | Within hit window across full song |
| Touch response | ≤1 frame input-to-registration latency |
| Memory | No growth over repeated plays (object pooling) |
| Crash rate | Zero crashes on normal playthrough |
| Device test | Verified on at least one physical Android device |

## Independence

Agent 06 independently verifies implementation quality; does not author the code under test. Test results recorded in TASK_REGISTER.md and reported to Agent 00.

## Automation

Tests runnable via Godot headless / GUT or equivalent; integrated into Agent 07 build automation where practical.
