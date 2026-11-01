# TASK REGISTER — PROJECT RHYTHM

Wave 1 — Discovery (COMPLETE)
- T-01 Repository audit: git repo initialized, existing Godot 4 project + Python pipeline audited
- T-02 Technology assessment: Godot 4 selected (existing project foundation); ADR recorded
- T-03 Environment audit: Python 3.14.6 + pip + numpy available; Godot/Android SDK/librosa/demucs NOT installed
- T-04 Reference-game analysis: Magic Tiles 3 core mechanics documented (4-lane, timing, scoring, progression)
- T-05 Engineering org design: 8 agents defined in AGENT_REGISTRY.md

Wave 2 — Architecture & Game Design (IN PROGRESS)
- T-06 Game Design Document: docs/game-design/GAME_DESIGN_DOCUMENT.md
- T-07 Architecture Decision Record: docs/architecture/ARCHITECTURE_DECISIONS.md
- T-08 Technical Roadmap: docs/TECHNICAL_ROADMAP.md
- T-09 System diagrams & interface definitions
- T-10 Agent system prompts: .agents/prompts/00-07.md
- T-11 Shared skills library: .agents/skills/
- T-12 Worktree & branch architecture: WORKTREE_REGISTRY.md + branch provisioning

Wave 3 — MVP Implementation (IN PROGRESS - AUTHORIZED 2026-10-31)

MVP-01 — Core architecture and game lifecycle (COMPLETE — 2026-10-31)
- All tasks complete. Test results on integrated main: 41 passed, 3 failed (laneCount mismatch — QA chart_loader tests expect 6, chart is 4). Defect carried into MVP-02.

MVP-02 — Four-lane gameplay and tile spawning (IN PROGRESS - AUTHORIZED 2026-11-01)
- T-MVP-02a [Agent 01 Architecture] Game state machine wiring, initialization contract, scene-to-controller bridge
- T-MVP-02b [Agent 02 Gameplay] 4-lane gameplay, tile spawning, hit detection, object pooling, input gating
- T-MVP-02c [Agent 03 Audio] Audio clock → gameplay integration, 4-lane chart validation
- T-MVP-02d [Agent 04 UI] Gameplay HUD, scene transitions, pause/resume wiring
- T-MVP-02e [Agent 05 Systems] Scoring query API, signals, initialization from chart
- T-MVP-02f [Agent 06 QA] Fix 3 failing tests, add gameplay tests (spawning, lanes, hit/miss, duplicate prevention, pool reuse)
- T-MVP-02g [Agent 07 Android] Export readiness docs, blocker tracking
- T-MVP-02h [Agent 00 Chief] Coordination, integration review, initialization contract enforcement

Wave 4 — Core Game Expansion (PENDING)
- T-24 Multiple songs + difficulty levels (Easy/Normal/Hard/Expert)
- T-25 Hold notes + simultaneous notes
- T-26 Song previews
- T-27 High scores + local player progression
- T-28 Improved animations

Wave 5 — Advanced Game Systems (PENDING)
- T-29 Endless Mode
- T-30 Rush Mode
- T-31 Challenge Mode
- T-32 Achievements
- T-33 Daily rewards
- T-34 Customization / visual themes

Wave 6 — Production Preparation (PENDING)
- T-35 Functional + regression testing
- T-36 Audio synchronization testing + latency calibration
- T-37 Performance profiling (60 FPS target)
- T-38 Device compatibility testing
- T-39 Release build verification + signing prep

Wave 7 — Future Expansion (PENDING — not first wave)
- T-40 Multiplayer battles
- T-41 Online leaderboards
- T-42 Cloud synchronization
- T-43 Licensed music catalogue

## Task status key

| Status | Meaning |
|--------|---------|
| COMPLETE | Verified done |
| IN PROGRESS | Actively being worked |
| PENDING | Approved but not started |
| BLOCKED | Waiting on dependency or approval |

## Dependencies

- T-06..T-12 depend on T-01..T-05 (complete)
- T-13..T-23 depend on T-06..T-12 and Agent 00 approval
- T-22 (APK) depends on Android SDK installation (currently blocked — no SDK present)
- T-23 depends on physical Android device/emulator availability (currently none detected)
