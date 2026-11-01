# MULTI-AGENT ENGINEERING SKILL

**Skill Name:** multi-agent-engineering  
**Version:** 1.0  
**Applies To:** All HexaRhythm agents (00-07)  
**Status:** ACTIVE

---

## PURPOSE

This skill defines the mandatory operating procedure for the HexaRhythm multi-agent engineering ecosystem. It establishes how tasks flow from creation through implementation, review, integration, and closure.

All agents MUST follow this workflow. No exceptions.

---

## CORE PRINCIPLES

1. **Single Source of Truth** — The `main` branch is the only integration branch. Specialists work in isolated branches/worktrees.
2. **Chief Engineer Gate** — Only Agent 00 may approve merges into `main`.
3. **Ownership Enforcement** — Each file has a designated primary owner. Cross-ownership changes require coordination.
4. **Verification Honesty** — Never claim a verification level (L1-L6) without actual evidence.
5. **Preservation First** — Never delete, reset, or overwrite existing work without explicit approval.
6. **Real Implementation** — Documentation-only deliverables are insufficient. Source code changes required.

---

## WORKFLOW: TASK LIFECYCLE

Every task follows this exact sequence:

```
TASK CREATION
     ↓
TASK ASSIGNMENT
     ↓
DEPENDENCY CHECK
     ↓
SPECIALIST IMPLEMENTATION
     ↓
SPECIALIST TESTING (L1-L3 minimum)
     ↓
SPECIALIST SELF-REVIEW
     ↓
INDEPENDENT QA REVIEW (Agent 06)
     ↓
CHIEF ENGINEER REVIEW (Agent 00)
     ↓
INTEGRATION INTO MAIN
     ↓
REGRESSION TESTING
     ↓
DOCUMENTATION UPDATE
     ↓
TASK CLOSURE
```

### Phase Details

#### TASK CREATION
- Chief Engineer (Agent 00) creates task with complete specification
- Task recorded in `management/TASK_REGISTER.md`
- Task ID format: `T-<MILESTONE>-<SEQ>` (e.g., `T-MVP-02a`)

#### TASK ASSIGNMENT
- Agent 00 assigns to specialist via task register update
- Specialist acknowledges in their worktree
- Dashboard updated (`management/AGENT_DASHBOARD.md`)

#### DEPENDENCY CHECK
- Specialist verifies all upstream tasks are COMPLETE (not just IN PROGRESS)
- Checks `management/TASK_REGISTER.md` for dependency status
- Reports blockers immediately if dependencies unmet

#### SPECIALIST IMPLEMENTATION
- Work ONLY in assigned branch/worktree
- Modify ONLY files within ownership (see Ownership Matrix)
- Follow existing code conventions and interfaces
- Make focused, atomic changes
- Add tests for new behavior

#### SPECIALIST TESTING
- Run relevant existing tests: `python -m pytest tests/ -v`
- Achieve minimum L2 (unit tests) for new code
- Document test results in task record
- **Never weaken tests to pass**

#### SPECIALIST SELF-REVIEW
- Verify implementation matches acceptance criteria
- Check for unintended side effects
- Confirm no cross-ownership violations
- Record commit hash and test results

#### INDEPENDENT QA REVIEW (Agent 06)
- Agent 06 reviews implementation independently
- Runs full test suite
- Checks for regressions
- Verifies test quality (not just coverage)
- Reports PASS/FAIL with evidence

#### CHIEF ENGINEER REVIEW (Agent 00)
- Reviews code changes, test results, QA report
- Verifies architectural consistency
- Checks integration readiness
- Approves or requests changes

#### INTEGRATION INTO MAIN
- Agent 00 merges approved branch into `main`
- Uses merge commit (no squash, no rebase)
- Records integration in `management/INTEGRATION_LOG.md`

#### REGRESSION TESTING
- Run full test suite on integrated `main`
- Verify all 46+ tests pass
- Report any failures immediately

#### DOCUMENTATION UPDATE
- Update relevant docs (architecture, API, testing)
- Update `management/EXECUTION_LOG.md`
- Update `management/AGENT_DASHBOARD.md`

#### TASK CLOSURE
- Mark task COMPLETE in `management/TASK_REGISTER.md`
- Record final commit hash
- Archive task artifacts if needed

---

## TASK SPECIFICATION FORMAT

Every task MUST contain:

```markdown
## Task: T-<ID> — <Title>

**Responsible Agent:** Agent <NN> — <Role>
**Objective:** <One-sentence goal>
**Background:** <Context, why this matters>
**Files Allowed to Change:** <Explicit list>
**Files Owned by Others (Request Changes Via):** <List>
**Dependencies:** <Task IDs that must be COMPLETE>
**Expected Deliverables:** <Concrete files/artifacts>
**Acceptance Criteria:** <Measurable, testable conditions>
**Required Tests:** <Specific test files/cases to add/run>
**Definition of Done:** <Checklist matching acceptance criteria>
**Priority:** <HIGH/MEDIUM/LOW>
**Deadline:** <Date or milestone>
```

---

## FILE OWNERSHIP MATRIX

| File/Directory | Primary Owner | Secondary (Review) |
|----------------|---------------|-------------------|
| `godot_project/scripts/core/GameController.gd` | Agent 01 | Agent 00 |
| `godot_project/scripts/core/GameStateManager.gd` | Agent 01 | Agent 00 |
| `godot_project/scripts/core/GameConfig.gd` | Agent 01 | Agent 00 |
| `godot_project/scripts/LaneManager.gd` | Agent 02 | Agent 00 |
| `godot_project/scripts/NoteSpawner.gd` | Agent 02 | Agent 00 |
| `godot_project/scripts/AudioSync.gd` | Agent 03 | Agent 00 |
| `godot_project/scripts/ChartLoader.gd` | Agent 03 | Agent 00 |
| `godot_project/scripts/OffsetCalibration.gd` | Agent 03 | Agent 00 |
| `godot_project/scripts/ScoreManager.gd` | Agent 05 | Agent 00 |
| `godot_project/scripts/systems/PlayerProfile.gd` | Agent 05 | Agent 00 |
| `godot_project/scripts/systems/SaveManager.gd` | Agent 05 | Agent 00 |
| `godot_project/scripts/systems/SongUnlockManager.gd` | Agent 05 | Agent 00 |
| `godot_project/scripts/GameScene.gd` | Agent 04 | Agent 01 |
| `godot_project/scenes/GameScene.tscn` | Agent 04 | Agent 01 |
| `godot_project/scenes/MainMenu.tscn` | Agent 04 | Agent 01 |
| `godot_project/scenes/SongSelection.tscn` | Agent 04 | Agent 01 |
| `godot_project/scenes/CalibrationScene.tscn` | Agent 04 | Agent 03 |
| `godot_project/scripts/ui/MainMenuUI.gd` | Agent 04 | Agent 01 |
| `godot_project/scripts/ui/SongSelectionUI.gd` | Agent 04 | Agent 01 |
| `godot_project/scripts/ui/GameSceneUI.gd` | Agent 04 | Agent 01 |
| `tests/` (all) | Agent 06 | Agent 00 |
| `docs/architecture/` | Agent 01 | Agent 00 |
| `docs/gameplay/` | Agent 02 | Agent 00 |
| `docs/audio/` | Agent 03 | Agent 00 |
| `docs/ui/` | Agent 04 | Agent 00 |
| `docs/systems/` | Agent 05 | Agent 00 |
| `docs/testing/` | Agent 06 | Agent 00 |
| `docs/android/` | Agent 07 | Agent 00 |
| `docs/management/` | Agent 00 | — |
| `android/` (export config) | Agent 07 | Agent 00 |
| `project.godot` (Android-relevant fields) | Agent 00 | Agent 07 |
| `.kilo/agent-manager.json` | Agent 00 | — |

**Rule:** If you need to modify a file owned by another agent, create a task requesting the change. Do not modify directly.

---

## VERIFICATION LEVELS

Every task must declare its achieved verification level:

| Level | Name | Requirements |
|-------|------|--------------|
| **L1** | Static Source Inspection | Code reviewed, compiles, follows conventions |
| **L2** | Automated Unit Tests | New unit tests pass, existing tests pass |
| **L3** | Integration Tests | Cross-component tests pass |
| **L4** | Godot Runtime Validation | Scene runs in Godot 4 editor, no errors |
| **L5** | Android Emulator Validation | APK installs/runs on emulator |
| **L6** | Physical Device Validation | APK tested on real Android device |

### Mandatory Rules

- **L4, L5, L6 require actual evidence** — Screenshots, logs, or video
- **If Godot/Android unavailable, max claim is L3** — Document blockers honestly
- **Never claim higher level without lower levels complete**
- **QA (Agent 06) validates claimed levels independently**

---

## AGENT BEHAVIOR STANDARDS

### All Agents Must

1. **Read before write** — Inspect existing code, docs, and task register before making changes
2. **Stay in lane** — Only modify owned files; request cross-ownership changes via tasks
3. **Commit atomically** — One logical change per commit with descriptive message
4. **Test before claiming** — Run tests, record actual results
5. **Report blockers immediately** — Update dashboard, notify Agent 00
6. **Document decisions** — Record in `management/DECISION_REGISTER.md`

### All Agents Must NOT

1. **Merge to main** — Only Agent 00 integrates
2. **Force-push** — Preserve history; use new commits
3. **Delete branches/worktrees** — Without Agent 00 approval
4. **Claim unimplemented work** — "Done" means verified deliverables exist
5. **Weaken tests** — To make them pass
6. **Create duplicate infrastructure** — Check existing first

---

## COMMUNICATION PROTOCOL

### Status Updates (Dashboard)

Agents update `management/AGENT_DASHBOARD.md` with:

| Field | Values |
|-------|--------|
| Status | `Idle` \| `Assigned` \| `Implementing` \| `Testing` \| `Awaiting Review` \| `Blocked` \| `Completed` |
| Current Task | Task ID |
| Latest Commit | Hash |
| Tests | Pass/Fail count |
| Blockers | Description or "None" |

### Blocker Reporting

When blocked, agent MUST:
1. Update dashboard status to `Blocked`
2. Add entry to `management/EXECUTION_LOG.md`
3. Notify Agent 00 via task comment

### Code Review

Reviews happen via:
1. Specialist self-review (checklist)
2. Agent 06 independent review (test execution + code review)
3. Agent 00 final review (architecture + integration)

Review checklist:
- [ ] Implementation matches acceptance criteria
- [ ] No cross-ownership violations
- [ ] Tests added for new behavior
- [ ] All existing tests pass
- [ ] No regressions introduced
- [ ] Code follows project conventions
- [ ] Documentation updated
- [ ] Verification level honestly reported

---

## INTEGRATION POLICY

### Pre-Integration Checklist (Agent 00)

- [ ] Specialist implementation complete
- [ ] Specialist self-review done
- [ ] Agent 06 QA review PASSED
- [ ] All tests pass on specialist branch
- [ ] No unresolved critical defects
- [ ] Commit history clean (no WIP, no merge conflicts)
- [ ] Documentation updated

### Integration Process

```bash
# From main worktree
git checkout main
git pull origin main
git merge --no-ff agent/project-rhythm-<specialist>
# Resolve any conflicts (coordinate with specialist)
# Run regression tests
python -m pytest tests/ -v
# Update dashboard and logs
```

### Post-Integration

- Record in `management/INTEGRATION_LOG.md`
- Update `management/AGENT_DASHBOARD.md`
- Run full regression suite
- Tag integration if milestone complete

---

## MILESTONE GATES

### MVP-02 Gate (Current)

**Entry Criteria:**
- [ ] GameController + GameStateManager integrated
- [ ] GameScene.gd complete (HUD, pause, results)
- [ ] LaneManager + NoteSpawner + AudioSync integrated
- [ ] ScoreManager signals connected
- [ ] Gameplay unit tests added (L2)
- [ ] All 46+ tests pass on main

**Exit Criteria:**
- [ ] Four-lane gameplay functional (L3 minimum)
- [ ] Tile spawning/movement per chart timing
- [ ] Lane input maps correctly
- [ ] Hit/miss handling works
- [ ] Scoring integration works
- [ ] Object pooling safe
- [ ] Pause/resume gating works
- [ ] Independent QA sign-off

### Future Milestones

Same pattern: Entry criteria → Implementation → QA → Integration → Gate review

---

## ESCALATION PATH

1. **Specialist blocked** → Notify Agent 00, update dashboard
2. **Cross-agent conflict** → Agent 00 mediates, records decision
3. **Architecture decision needed** → Agent 00 records in `DECISION_REGISTER.md`
4. **Critical defect in main** → Agent 00 coordinates hotfix, all agents pause related work
5. **Milestone gate failure** → Agent 00 analyzes, replans, communicates

---

## TOOLS & COMMANDS

### Standard Test Command
```bash
cd /home/abhaysawant/hexa-rhythm
python -m pytest tests/ -v
```

### Worktree Navigation
```bash
# List worktrees
git worktree list

# Switch to specialist worktree
cd /home/abhaysawant/project-rhythm-<specialist>

# Return to main
cd /home/abhaysawant/hexa-rhythm
```

### Status Check
```bash
# Check branch status
git status
git log --oneline -5

# Check dashboard
cat management/AGENT_DASHBOARD.md
```

---

## REFERENCES

- `management/AGENT_REGISTRY.md` — Agent identities and ownership
- `management/TASK_REGISTER.md` — Task definitions and status
- `management/EXECUTION_LOG.md` — Activity log
- `management/WORKTREE_REGISTRY.md` — Worktree mapping
- `docs/architecture/ARCHITECTURE_DECISIONS.md` — ADRs
- `docs/TECHNICAL_ROADMAP.md` — Milestone plan
- `docs/testing/TESTING_STRATEGY.md` — Test approach

---

## CHANGE LOG

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-01 | Agent 00 | Initial version |