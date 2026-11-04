# WORKTREE REGISTRY — PROJECT RHYTHM

Integration branch: main (repository default)
Worktree root: /home/abhaysawant/hexa-rhythm (worktrees are sibling directories of the repo)

## Active Developer Worktrees (8)

| Agent | Worktree Directory | Branch | Base | Purpose | Status |
|-------|-------------------|--------|------|---------|--------|
| 00 Chief Engineer | /home/abhaysawant/project-rhythm-chief | agent/project-rhythm-chief | main | Org, integration, releases | Active |
| 01 Architecture | /home/abhaysawant/project-rhythm-architecture | agent/project-rhythm-architecture | main | Engine architecture, scenes | Ready for integration |
| 02 Gameplay | /home/abhaysawant/project-rhythm-gameplay | agent/project-rhythm-gameplay | main | Tiles, input, hit registration | Active (merged main) |
| 03 Audio | /home/abhaysawant/project-rhythm-audio | agent/project-rhythm-audio | main | Music sync, timing, charts | Active |
| 04 UI/UX | /home/abhaysawant/project-rhythm-ui | agent/project-rhythm-ui | main | Menus, HUD, results, settings | Active |
| 05 Game Systems | /home/abhaysawant/project-rhythm-systems | agent/project-rhythm-systems | main | Progression, persistence | Ready for integration |
| 06 QA | /home/abhaysawant/project-rhythm-qa | agent/project-rhythm-qa | main | Tests, profiling | Active |
| 07 Android Release | /home/abhaysawant/project-rhythm-android | agent/project-rhythm-android | main | SDK, APK, signing | Blocked (no SDK) |

## Kilo Internal Worktrees (8 — Duplicate -2 Branches)

| Agent | Worktree Path | Branch | Base | Purpose | Status |
|-------|---------------|--------|------|---------|--------|
| 01 Architecture | .kilo/worktrees/agent-project-rhythm-architecture-2-0caa8a41ee27ecce | agent/project-rhythm-architecture-2 | main | Kilo session tracking | Stale (1ded253) |
| 02 Gameplay | .kilo/worktrees/agent-project-rhythm-gameplay-2-8c945a51f35af626 | agent/project-rhythm-gameplay-2 | main | Kilo session tracking | Stale (1ded253) |
| 03 Audio | .kilo/worktrees/agent-project-rhythm-audio-2-37415d8b4134d847 | agent/project-rhythm-audio-2 | main | Kilo session tracking | Stale (1ded253) |
| 04 UI/UX | .kilo/worktrees/agent-project-rhythm-ui-2-1697a689b76ebae4 | agent/project-rhythm-ui-2 | main | Kilo session tracking | Stale (1ded253) |
| 05 Systems | .kilo/worktrees/agent-project-rhythm-systems-2-b18951fb28acfb45 | agent/project-rhythm-systems-2 | main | Kilo session tracking | Stale (1ded253) |
| 06 QA | .kilo/worktrees/agent-project-rhythm-qa-2-07393b6d766b11cd | agent/project-rhythm-qa-2 | main | Kilo session tracking | Stale (1ded253) |
| 07 Android | .kilo/worktrees/agent-project-rhythm-android-2-62636c98feda9f1a | agent/project-rhythm-android-2 | main | Kilo session tracking | Stale (1ded253) |
| (Chief) | .kilo/worktrees/hexa-rhythm-f84ef3bd5fb5/navy-pelican | (detached) | main | Kilo pool | Stale |

**Note:** These -2 branches and kilo worktrees are internal Agent Manager artifacts. They duplicate the developer worktrees at an older commit (1ded253, pre-MVP-02 authorization). Recommendation: Archive or delete with approval.

## Provisioning Procedure (Agent 00 Only)

For each new agent:
1. `git checkout -b <branch> main`
2. `git worktree add /home/abhaysawant/project-rhythm-<agent> <branch>`
3. Confirm via `git worktree list`
4. Record session ID in AGENT_REGISTRY.md once Agent Manager session verified active

## Constraints (Mandatory)

- Do not force-push.
- Do not delete branches without Agent 00 approval.
- Do not delete worktrees without Agent 00 approval.
- Specialists do not merge independently; integration via Agent 00 only.
- Preserve existing committed work on main.
- Never claim a worktree exists unless `git worktree list` confirms it.

## Current State (Verified 2026-11-01)

- All 8 developer worktrees provisioned as sibling directories (confirmed via `git worktree list`).
- Repository default branch: main (commit 1c13e83).
- 8 specialist Agent Manager sessions started (pending verification in AGENT_REGISTRY.md).
- 8 duplicate -2 branches exist at commit 1ded253 (stale).
- 8 kilo internal worktrees tracking -2 branches.
- 1 detached kilo pool worktree.

## Cleanup Actions Required

1. Archive/delete -2 branches (Agent 00 approval needed)
2. Remove kilo internal worktrees (Agent 00 approval needed)
3. Verify specialist session IDs in AGENT_REGISTRY.md
## Continuation snapshot — 2026-11-02

The previously listed primary sibling worktrees and internal Kilo worktrees remain preserved. This continuation made no new worktree or branch. Live agent activity was not verified from the current workspace, so the historical `Active` labels above should not be read as confirmation of ongoing participation.

Current continuation changes are in the primary `main` workspace and are not specialist worktree contributions. Existing dirty/staged state remains preserved; no branches or worktrees were created or removed.
