# HEXARHYTHM GITHUB CONTRIBUTION ROADMAP

**Repository:** https://github.com/abhayshravan357-sudo/rhythm-rush  
**Owner:** abhayshravan357-sudo  
**Agent ecosystem:** 8 agents (00 Chief + 01-07 specialists)  
**Worktree policy:** Permanent — reuse existing 8 worktrees only, no new agents/sessions/branches  
**Current baseline:** MVP-03 complete, main@e0c372a, 141 Python tests + 27 Godot runtime tests passing

---

## Multi-Agent Execution Strategy

Agent 00 (Chief Engineer) is the sole integration coordinator. All other agents work in their assigned worktrees/branches only. Independent tasks execute in parallel; integration is centralized through Agent 00 after review.

## Contribution Roadmap — Batch 1 (10 contributions)

Each task has a unique ID, assigned specialist, non-conflicting file scope, acceptance criteria, and required tests.

| CID | Agent | Domain | Task | Files (primary owner) | Acceptance Criteria | Tests |
|-----|-------|--------|------|----------------------|---------------------|-------|
| C-001 | 01 Architecture | Architecture | Extract `GameConfig` lane/scoring constants into separate named config constants file | godot_project/scripts/core/GameConfig.gd | Lane/scoring constants grouped, no behavior change | tests/test_game_config.py pass |
| C-002 | 01 Architecture | Architecture | Create `SceneLoader.gd` autoload — centralized scene loading with error handling and existence checks | godot_project/scripts/core/SceneLoader.gd (new) | Missing scene returns null + printerr, no crash | tests/unit/test_scene_loader.py |
| C-003 | 02 Gameplay | Gameplay | Add HOLD note visual lane path rendering — draw hold note duration bar from hit line upward | godot_project/scripts/LaneManager.gd | HOLD notes render as vertical bar anchored at judgment line | tests/unit/test_lane_manager.py |
| C-004 | 02 Gameplay | Gameplay | Add touch deadzone configuration — configurable deadzone radius for mobile tap accuracy | godot_project/scripts/LaneManager.gd | Deadzone rejects taps outside lane bounds + configurable radius | tests/unit/test_lane_manager.py |
| C-005 | 03 Audio | Audio | Add `get_remaining_song_time()` — returns seconds remaining for UI countdown | godot_project/scripts/AudioSync.gd | Returns 0 at song start, decreases to 0 at end | tests/unit/test_audio_sync.py |
| C-006 | 03 Audio | Audio | Add `warp_to_position(seconds)` — seek audio to arbitrary position with adjusted time sync | godot_project/scripts/AudioSync.gd | Seek updates both clocks, no negative time | tests/unit/test_audio_sync.py |
| C-007 | 04 UI/UX | UI | Add gameplay HUD song title + progress bar — shows current song and playback progress | godot_project/scripts/ui/GameScene HUD + GameScene.tscn | Title visible, progress bar moves 0→100% | tests/integration/test_gameplay_flow.py |
| C-008 | 04 UI/UX | UI | Add responsive HUD scaling for compact screens (< 480px width) | godot_project/scripts/ui/UI components | UI scales without overflow at small viewport | tests/unit/test_responsive_layout.py |
| C-009 | 05 Systems | Systems | Add `PlayerProfile.add_xp` validation guard — reject negative XP amounts | godot_project/scripts/systems/PlayerProfile.gd | Negative XP is ignored, no crash | tests/unit/test_scoring.py |
| C-010 | 06 QA | QA | Add ChartLoader invalid lane rejection test — notes with lane >= laneCount are dropped | tests/unit/test_chart_loader_validation.py (new) | Invalid lane notes excluded from chart | tests/unit/test_chart_loader_validation.py |
| C-011 | 06 QA | QA | Add LaneManager boundary test — touch at playfield edges returns correct lane or -1 | tests/unit/test_lane_manager.py | Edge touches mapped correctly | tests/unit/test_lane_manager.py |
| C-012 | 07 Android | Android | Add Android export preset for release configuration — signing config placeholder | android/EXPORT_PRESET.md (docs) + godot_project/export_presets.cfg | Release preset documented, debug preset unchanged | android docs build check |
| C-013 | 07 Android | Android | Add Android touch input configuration documentation — touch deadzone, multitouch handling | docs/android/ANDROID_TOUCH_CONFIG.md (new) | Touch config documented for developers | docs review |
| C-014 | 00 Chief | Coordination | Create GITHUB_CONTRIBUTION_ROADMAP.md — this document | management/GITHUB_CONTRIBUTION_ROADMAP.md (new) | All 8 agents have assigned tasks | docs review |
| C-015 | 00 Chief | Coordination | Update AGENT_REGISTRY.md with current batch 1 assignments and session status | management/AGENT_REGISTRY.md | All agents have current status | docs review |

---

## Batch 2 (Planned — 10 contributions)

| CID | Agent | Domain | Task |
|-----|-------|--------|------|
| C-016 | 01 Architecture | Architecture | Extract autoload dependency graph — document init order and circular dep risks |
| C-017 | 02 Gameplay | Gameplay | Add SIMULTANEOUS chord note judgment — multiple lanes hit at same timestamp |
| C-018 | 03 Audio | Audio | Add timing drift compensation — auto-adjust local_hardware_offset based on drift_samples |
| C-019 | 04 UI/UX | UI | Add judgment feedback color flash — PERFECT/GOOD/MISS color-coded flash |
| C-020 | 05 Systems | Systems | Add save file integrity checksum — detect corrupted user:// data |
| C-021 | 05 Systems | Systems | Add SongUnlockManager unlock-on-score-threshold — unlock songs by score |
| C-022 | 06 QA | QA | Add Godot headless test for scene loading — all scenes load without error |
| C-023 | 06 QA | QA | Add performance test — object pool reuse doesn't leak nodes |
| C-024 | 07 Android | Android | Add Android ADB device test script — install + launch smoke check |
| C-025 | 07 Android | Android | Add Android permissions audit — minimal permissions only |

---

## Batch 3+ (Planned)

C-026 through C-100 will be defined after batch 2 completes, based on actual findings and priority. Domains not yet covered: Endless mode, Rush mode, Challenge mode, Daily Challenge, achievements, cloud sync, online leaderboards, licensed music, performance profiling, battery optimization, accessibility controls, CI/CD pipeline, release signing.

---

## Integration Protocol

1. Agent 00 identifies independent tasks (no shared file writes)
2. Specialists implement in their worktrees
3. Agent 06 runs relevant tests
4. Agent 01 reviews architecture implications
5. Agent 00 reviews diffs, integrates into main
6. Regression suite runs (141+ tests)
7. Commits pushed to origin/main

---

## Git Attribution Policy

All commits use the repository owner's Git identity:
- Name: Abhay Sawant
- Email: abhayshravan357@gmail.com
- No Kilo/kilocode attribution in commits
- No co-authors added without explicit approval

---

## Definition of a Genuine Contribution

A contribution must produce:
1. Real implementation (not placeholder/todo)
2. Relevant tests (where applicable)
3. Test execution evidence
4. Reviewed Git diff
5. Meaningful commit
6. Entry in this register

Empty commits, whitespace-only changes, and artificial activity are prohibited.