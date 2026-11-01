# DECISION REGISTER — PROJECT RHYTHM

Records architectural and technical decisions made during development.

| ID | Date (UTC) | Decision | Rationale | Author | Status |
|----|------------|----------|-----------|--------|--------|
| ADR-001 | 2026-10-31 | Godot 4 selected as engine | Existing project foundation; GDScript familiarity; Android export support; free/open source | Agent 00 | ACCEPTED |
| ADR-002 | 2026-10-31 | 8-agent specialization model | Separation of concerns: architecture, gameplay, audio, UI, systems, QA, Android; Chief coordinates | Agent 00 | ACCEPTED |
| ADR-003 | 2026-10-31 | Offline-first architecture | No network dependency for core gameplay; network only for optional catalog sync | Agent 00 | ACCEPTED |
| ADR-004 | 2026-10-31 | Audio-clock-based timing (AudioSync) | Hardware clock (get_playback_position + get_time_since_last_mix) prevents frame-delta drift on mobile | Agent 03 | ACCEPTED |
| ADR-005 | 2026-10-31 | Four-lane MVP with six-lane headroom | Magic Tiles 3 reference uses 4 lanes; GameConfig.ALLOWED_LANE_COUNTS = [4, 6] | Agent 01 | ACCEPTED |
| ADR-006 | 2026-10-31 | Object pooling for tiles (NoteSpawner) | Pre-allocate ColorRect nodes (MAX_POOL_LIMIT=200) to eliminate GC pauses on mobile | Agent 02 | ACCEPTED |
| ADR-007 | 2026-10-31 | Hit windows: PERFECT ≤50ms (300pts), GOOD ≤100ms (100pts), MISS >100ms (0pts) | Standard rhythm game timing; mirrors mobile genre conventions | Agent 05 | ACCEPTED |
| ADR-008 | 2026-10-31 | Score never negative; miss resets combo | Prevents score exploitation; standard scoring model | Agent 05 | ACCEPTED |
| ADR-009 | 2026-10-31 | Duplicate-hit prevention via resolved_flags | Each note resolved once; ScoreManager tracks per-note resolution | Agent 05 | ACCEPTED |
| ADR-010 | 2026-10-31 | Chart validation rejects invalid lane indices | Lane must be 0 ≤ lane < laneCount; ChartLoader.normalize_lane_count enforces | Agent 03 | ACCEPTED |
| ADR-011 | 2026-11-01 | LaneCount=4 for MVP charts; 6-lane compatibility preserved | conftest.py LANE_COUNT=4, SIX_LANE_COUNT=6 fixture; test_six_lane_chart_compatibility validates | Agent 00 | ACCEPTED |
| ADR-012 | 2026-11-01 | Multi-agent engineering skill as governance | Mandatory workflow, ownership matrix, verification levels, integration policy | Agent 00 | ACCEPTED |
| ADR-013 | 2026-11-01 | Integration order: GameController → PlayerProfile → GameScene → Gameplay/Audio → Tests | GameController unblocks all; PlayerProfile for persistence; GameScene for UI wiring; tests last | Agent 00 | PROPOSED |
| ADR-014 | 2026-11-01 | Duplicate -2 branches to be archived | 8 stale branches at commit 1ded253; kilo worktrees internal; cleanup with approval | Agent 00 | PROPOSED |
| ADR-015 | 2026-11-01 | No L4+ claims without Godot/Android installed | Verification honesty: max L3 (integration tests) achievable in current environment | Agent 00 | ACCEPTED |

## Decision Process

1. Any agent may propose a decision (ADR)
2. Agent 00 reviews and records in this register
3. Cross-cutting decisions require specialist input
4. Accepted decisions become binding constraints
5. Proposed decisions await final approval

## Template for New Decisions

```markdown
| ADR-XXX | YYYY-MM-DD | <Title> | <Rationale> | Agent NN | PROPOSED/ACCEPTED/REJECTED |
```