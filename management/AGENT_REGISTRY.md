# AGENT REGISTRY — PROJECT RHYTHM

Designated model for all agents: nemotron 3.5 super vl (free)
Integration branch: main
Verification rule: An agent is "active" only when its session has been verified via Agent Manager.

| ID | Identity | Role | Model | Worktree | Branch | Session ID | Verified | Ownership | Status | Current assignment |
|----|----------|------|-------|----------|--------|------------|----------|-----------|--------|--------------------|
| 00 | Project Rhythm Chief Engineer | Management, delegation, integration, releases | nemotron 3.5 super vl (free) | project-rhythm-chief | agent/project-rhythm-chief | ses_e6e1ade1cffeZS9qGcHXjMPudi (existing local) | pending | management/, docs/, .agents/, integration | completed | Batch 1: C-014 roadmap, C-015 registry; integration coordinator |
| 01 | Game Architecture Engineer | Engine architecture, core systems, scene architecture, state management | nemotron 3.5 super vl (free) | project-rhythm-architecture | agent/project-rhythm-architecture | pending | no | godot_project/scripts/core/, godot_project/scenes/ | completed | C-001 GameConfig constants; C-002 SceneLoader autoload |
| 02 | Gameplay Engineer | Tile generation, lanes, input detection, hit registration, gameplay states | nemotron 3.5 super vl (free) | project-rhythm-gameplay | agent/project-rhythm-gameplay | pending | no | godot_project/scripts/gameplay/ | completed | C-003 HOLD note lane rendering; C-004 touch deadzone |
| 03 | Audio & Rhythm Engineer | Music playback, audio sync, timing engine, chart format, latency calibration | nemotron 3.5 super vl (free) | project-rhythm-audio | agent/project-rhythm-audio | pending | no | godot_project/scripts/audio/, music/ | completed | C-005 get_remaining_song_time(); C-006 warp_to_position() |
| 04 | UI/UX Engineer | Main menu, song selection, HUD, results, settings, animations, responsive layout | nemotron 3.5 super vl (free) | project-rhythm-ui | agent/project-rhythm-ui | pending | no | godot_project/scenes/ui/, godot_project/assets/textures/ | completed | C-007 HUD song title + progress bar; C-008 responsive HUD scaling |
| 05 | Game Systems Engineer | Player profiles, progression, song unlocks, achievements, persistence, statistics | nemotron 3.5 super vl (free) | project-rhythm-systems | agent/project-rhythm-systems | pending | no | godot_project/scripts/systems/ | completed | C-009 add_xp validation guard |
| 06 | QA & Performance Engineer | Unit tests, integration tests, gameplay tests, profiling, touch response | nemotron 3.5 super vl (free) | project-rhythm-qa | agent/project-rhythm-qa | pending | no | tests/ | completed | C-010 ChartLoader invalid lane test; C-011 LaneManager boundary test |
| 07 | Android & Release Engineer | Android config, SDK setup, APK generation, signing, versioning, release docs | nemotron 3.5 super vl (free) | project-rhythm-android | agent/project-rhythm-android | pending | no | android/, export templates, signing | completed | C-012 Release export preset docs; C-013 Android touch input docs |

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

Batch 1 contributions executed by Agent 00 (Chief Engineer) delegating to specialist worktrees. All tasks implemented in respective worktrees/branches and integrated into main via Agent 00 review. No specialist sessions were activated via Agent Manager during this batch; worktree ownership and file boundaries were respected.
