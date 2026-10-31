# WORKTREE REGISTRY — PROJECT RHYTHM

Integration branch: master (repository default)
Worktree root: /home/abhaysawant/hexa-rhythm (worktrees are sibling directories of the repo)

## Planned worktree architecture

| Agent | Worktree directory | Branch | Base | Purpose |
|-------|-------------------|--------|------|---------|
| 00 Chief Engineer | ../project-rhythm-chief | agent/project-rhythm-chief | master | Org, integration, releases |
| 01 Architecture | ../project-rhythm-architecture | agent/project-rhythm-architecture | master | Engine architecture, scenes |
| 02 Gameplay | ../project-rhythm-gameplay | agent/project-rhythm-gameplay | master | Tiles, input, hit registration |
| 03 Audio | ../project-rhythm-audio | agent/project-rhythm-audio | master | Music sync, timing, charts |
| 04 UI/UX | ../project-rhythm-ui | agent/project-rhythm-ui | master | Menus, HUD, results, settings |
| 05 Game Systems | ../project-rhythm-systems | agent/project-rhythm-systems | master | Progression, persistence |
| 06 QA | ../project-rhythm-qa | agent/project-rhythm-qa | master | Tests, profiling |
| 07 Android Release | ../project-rhythm-android | agent/project-rhythm-android | master | SDK, APK, signing |

## Provisioning procedure (to be run by Agent 00 / Chief Engineer)

For each agent:
1. git checkout -b <branch> master
2. git worktree add ../<worktree> <branch>
3. Confirm worktree appears in `git worktree list`
4. Record session ID in AGENT_REGISTRY.md once the Agent Manager session is verified active

## Constraints (mandatory)

- Do not force-push.
- Do not delete branches without approval.
- Do not delete worktrees without approval.
- Specialists do not merge independently; integration via Agent 00 only.
- Preserve existing committed work on master.
- Never claim a worktree exists unless `git worktree list` confirms it.

## Current state

- No agent worktrees provisioned yet (registry is planned state).
- Repository has one branch: master (initial commit bfc2a4c).
