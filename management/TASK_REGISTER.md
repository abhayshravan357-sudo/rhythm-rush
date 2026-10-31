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

Wave 3 — Playable MVP (PENDING — awaits Wave 2 approval)
- T-13 Main menu (logo, play, song library, settings)
- T-14 Song selection (catalogue, locked/unlocked, preview)
- T-15 One playable song (original/public-domain audio)
- T-16 Four-lane tile gameplay with descending tiles
- T-17 Music synchronization (audio clock, not frame delta)
- T-18 Touch detection & hit registration
- T-19 Scoring, combo, accuracy
- T-20 Game-over & results screens
- T-21 Restart functionality
- T-22 Android debug APK generation
- T-23 MVP verification on real Android device

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
