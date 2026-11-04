# AGENT REGISTRY — PROJECT RHYTHM

Designated model for all agents: nemotron 3.5 super vl (free)
Integration branch: main
Verification rule: An agent is "active" only when its session has been verified via Agent Manager.

| ID | Identity | Role | Model | Worktree | Branch | Session ID | Verified | Ownership | Status | Current assignment |
|----|----------|------|-------|----------|--------|------------|----------|-----------|--------|--------------------|
| 00 | Project Rhythm Chief Engineer | Management, delegation, integration, releases | nemotron 3.5 super vl (free) | project-rhythm-chief | agent/project-rhythm-chief | ses_e6e1ade1cffeZS9qGcHXjMPudi (existing local) + Agent Manager session pending | pending | management/, docs/, .agents/, integration | in_progress | MVP-01 coordination across all 8 agents |
| 01 | Game Architecture Engineer | Engine architecture, core systems, scene architecture, state management | nemotron 3.5 super vl (free) | project-rhythm-architecture | agent/project-rhythm-architecture | pending (Agent Manager starting) | no | godot_project/scripts/core/, godot_project/scenes/ | assigned | MVP-01: Game state machine, autoload verification |
| 02 | Gameplay Engineer | Tile generation, lanes, input detection, hit registration, gameplay states | nemotron 3.5 super vl (free) | project-rhythm-gameplay | agent/project-rhythm-gameplay | pending (Agent Manager starting) | no | godot_project/scripts/gameplay/ | assigned | MVP-01: 4-lane lane management, touch input |
| 03 | Audio & Rhythm Engineer | Music playback, audio sync, timing engine, chart format, latency calibration | nemotron 3.5 super vl (free) | project-rhythm-audio | agent/project-rhythm-audio | pending (Agent Manager starting) | no | godot_project/scripts/audio/, music/ | assigned | MVP-01: AudioSync verification |
| 04 | UI/UX Engineer | Main menu, song selection, HUD, results, settings, animations, responsive layout | nemotron 3.5 super vl (free) | project-rhythm-ui | agent/project-rhythm-ui | pending (Agent Manager starting) | no | godot_project/scenes/ui/, godot_project/assets/textures/ | assigned | MVP-01: Menu structure, scene transitions |
| 05 | Game Systems Engineer | Player profiles, progression, song unlocks, achievements, persistence, statistics | nemotron 3.5 super vl (free) | project-rhythm-systems | agent/project-rhythm-systems | pending (Agent Manager starting) | no | godot_project/scripts/systems/ | assigned | MVP-01: ScoreManager API, local persistence |
| 06 | QA & Performance Engineer | Unit tests, integration tests, gameplay tests, profiling, touch response | nemotron 3.5 super vl (free) | project-rhythm-qa | agent/project-rhythm-qa | pending (Agent Manager starting) | no | tests/ | assigned | MVP-01: Test framework, scoring unit tests |
| 07 | Android & Release Engineer | Android config, SDK setup, APK generation, signing, versioning, release docs | nemotron 3.5 super vl (free) | project-rhythm-android | agent/project-rhythm-android | pending (Agent Manager starting) | no | android/, export templates, signing | assigned | MVP-01: Export preset verification |

## Session verification log

- ses_e6e1ade1cffeZS9qGcHXjMPudi (local, idle) — Agent 00 Chief Engineer orchestration session.
- Agent 01-07 sessions started via Agent Manager (request am-1793461032693-ljkx1m). Session IDs pending confirmation via Agent Manager.
- Verified = false for all specialists until sessions are confirmed active via Agent Manager.

## File ownership policy

- Each agent owns the directories listed under "Ownership."
- Agents must not modify files outside their ownership without Agent 00 coordination.
- Shared files (project.godot, autoloads, manifest) are owned by Agent 00; changes require Chief Engineer approval.
- Existing committed code (godot_project/, charts/, pipeline/) is preserved; specialists extend, not rewrite, without approval.

## Continuation activity verification — 2026-11-02

No specialist session was activated or assigned during the current Codex workspace continuation. The repository and external sibling worktrees are present, but current live participation could not be independently queried from this session. Do not infer that Agents 01–07 contributed to the continuation changes; Agent 00 (current workspace) owns the recorded edits and validation above. Existing session verification entries are retained as historical state.
