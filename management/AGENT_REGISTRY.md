# AGENT REGISTRY — PROJECT RHYTHM

Designated model for all agents: nemotron 3.5 super vl (free)
Integration branch: main
Verification rule: An agent is "active" only when its session has been verified via Agent Manager.

| ID | Identity | Role | Model | Worktree | Branch | Session ID | Verified | Ownership | Status | Current assignment |
|----|----------|------|-------|----------|--------|------------|----------|-----------|--------|--------------------|
| 00 | Project Rhythm Chief Engineer | Management, delegation, integration, releases | nemotron 3.5 super vl (free) | project-rhythm-chief | agent/project-rhythm-chief | — | no | management/, docs/, .agents/, integration | assigned | Org setup, delegation, integration planning |
| 01 | Game Architecture Engineer | Engine architecture, core systems, scene architecture, state management | nemotron 3.5 super vl (free) | project-rhythm-architecture | agent/project-rhythm-architecture | — | no | godot_project/scripts/core/, godot_project/scenes/ | assigned | Architecture & scene design |
| 02 | Gameplay Engineer | Tile generation, lanes, input detection, hit registration, gameplay states | nemotron 3.5 super vl (free) | project-rhythm-gameplay | agent/project-rhythm-gameplay | — | no | godot_project/scripts/gameplay/ | assigned | Core gameplay implementation |
| 03 | Audio & Rhythm Engineer | Music playback, audio sync, timing engine, chart format, latency calibration | nemotron 3.5 super vl (free) | project-rhythm-audio | agent/project-rhythm-audio | — | no | godot_project/scripts/audio/, music/ | assigned | Audio timing architecture |
| 04 | UI/UX Engineer | Main menu, song selection, HUD, results, settings, animations, responsive layout | nemotron 3.5 super vl (free) | project-rhythm-ui | agent/project-rhythm-ui | — | no | godot_project/scenes/ui/, godot_project/assets/textures/ | assigned | UI screens & responsive layout |
| 05 | Game Systems Engineer | Player profiles, progression, song unlocks, achievements, persistence, statistics | nemotron 3.5 super vl (free) | project-rhythm-systems | agent/project-rhythm-systems | — | no | godot_project/scripts/systems/ | assigned | Progression & local save |
| 06 | QA & Performance Engineer | Unit tests, integration tests, gameplay tests, profiling, touch response | nemotron 3.5 super vl (free) | project-rhythm-qa | agent/project-rhythm-qa | — | no | tests/ | assigned | Test strategy & verification |
| 07 | Android & Release Engineer | Android config, SDK setup, APK generation, signing, versioning, release docs | nemotron 3.5 super vl (free) | project-rhythm-android | agent/project-rhythm-android | — | no | android/, export templates, signing | assigned | Android build & release prep |

## Session verification log

- ses_e6e1ade1cffeZS9qGcHXjMPudi (local, busy) — current orchestration session. Not assigned to a specialist worktree.
- No specialist sessions have been started yet. Verified = false for all specialists until sessions are created and confirmed via Agent Manager.

## File ownership policy

- Each agent owns the directories listed under "Ownership."
- Agents must not modify files outside their ownership without Agent 00 coordination.
- Shared files (project.godot, autoloads, manifest) are owned by Agent 00; changes require Chief Engineer approval.
- Existing committed code (godot_project/, charts/, pipeline/) is preserved; specialists extend, not rewrite, without approval.
