# AGENT DASHBOARD — PROJECT RHYTHM

Project: PROJECT RHYTHM
Working directory: /home/abhaysawant/hexa-rhythm
Integration branch: main (actual repository default)
Designated model: nemotron 3.5 super vl (free) — all worktree agents
Reference gameplay: Magic Tiles 3 (gameplay inspiration only — no copied assets/IP)
Product goal: Original, offline-first Android rhythm game APK

## Executive status

| Area | Status | Notes |
|------|--------|-------|
| Repository | initialized | Git repo at /home/abhaysawant/hexa-rhythm, branch master |
| Existing code | preserved | Godot 4 project + Python chart pipeline committed (bfc2a4c) |
| Agent org | specified | 8 agents (1 manager + 7 specialists) in this dashboard |
| Worktrees | planned | Branches created; worktrees to be provisioned per agent |
| Technology | Godot 4 | ADR recorded in docs/architecture/ARCHITECTURE_DECISIONS.md |
| Android SDK | NOT installed | Manual install required (see docs/TECHNICAL_ROADMAP.md) |
| Godot | NOT installed | Manual install required for editor/export |
| APK build | blocked | No Android toolchain present yet |

## Agent assignments at a glance

| Agent | Identity | Role | Branch | Worktree | Status | Current assignment |
|-------|----------|------|--------|----------|--------|--------------------|
| 00 | Project Rhythm Chief Engineer | Management / integration / releases | agent/project-rhythm-chief | project-rhythm-chief | assigned | Org setup, delegation, integration |
| 01 | Game Architecture Engineer | Engine architecture, core systems, scenes | agent/project-rhythm-architecture | project-rhythm-architecture | assigned | Architecture & scene design |
| 02 | Gameplay Engineer | Tiles, lanes, input, hit registration | agent/project-rhythm-gameplay | project-rhythm-gameplay | assigned | Core gameplay implementation |
| 03 | Audio & Rhythm Engineer | Music sync, timing, charts, latency | agent/project-rhythm-audio | project-rhythm-audio | assigned | Audio timing architecture |
| 04 | UI/UX Engineer | Menus, HUD, results, settings, animations | agent/project-rhythm-ui | project-rhythm-ui | assigned | UI screens & responsive layout |
| 05 | Game Systems Engineer | Profiles, progression, unlocks, persistence | agent/project-rhythm-systems | project-rhythm-systems | assigned | Progression & local save |
| 06 | QA & Performance Engineer | Testing, profiling, touch response | agent/project-rhythm-qa | project-rhythm-qa | assigned | Test strategy & verification |
| 07 | Android & Release Engineer | SDK, APK, signing, versioning, release | agent/project-rhythm-android | project-rhythm-android | assigned | Android build & release prep |

## Integration rules (mandatory)

- No specialist merges independently. All integration goes through Agent 00 (Chief Engineer) and review.
- No force-push. No branch deletion without approval. No worktree deletion without approval.
- Specialists only modify files within their assigned ownership; cross-ownership changes require Agent 00 coordination.
- Preserve all existing work (godot_project/, charts/, pipeline/, .kilo/).
- Never claim an agent, branch, worktree, file, APK, or build exists unless created and verified.

## Waves (controlled development)

- Wave 1 — Discovery: read-only inspection (COMPLETE — environment audited)
- Wave 2 — Architecture & Game Design: GDD, ADR, system diagrams, roadmap (IN PROGRESS)
- Wave 3 — Playable MVP: menu, song selection, one song, 4-lane gameplay, sync, scoring, restart, APK
- Wave 4 — Core Expansion: multiple songs, difficulties, hold notes, simultaneous notes, previews, progression
- Wave 5 — Advanced Systems: Endless/Rush/Challenge modes, achievements, daily rewards, customization
- Wave 6 — Production: functional/regression/audio/perf/device testing, release build verification
- Wave 7 — Future: multiplayer, leaderboards, cloud sync, licensed music (NOT first wave)

## Quick links

- Agent Registry: management/AGENT_REGISTRY.md
- Worktree Registry: management/WORKTREE_REGISTRY.md
- Task Register: management/TASK_REGISTER.md
- Execution Log: management/EXECUTION_LOG.md
- Architecture Decision Record: docs/architecture/ARCHITECTURE_DECISIONS.md
- Game Design Document: docs/game-design/GAME_DESIGN_DOCUMENT.md
- Technical Roadmap: docs/TECHNICAL_ROADMAP.md
- Agent prompts: .agents/prompts/00-*.md ... 07-*.md
- Shared skills: .agents/skills/
