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
- T-11 Shared skills library: .agents/skills/ (multi-agent-engineering.md CREATED 2026-11-01)
- T-12 Worktree & branch architecture: WORKTREE_REGISTRY.md + branch provisioning

Wave 3 — MVP Implementation (IN PROGRESS - AUTHORIZED 2026-10-31)

MVP-01 — Core architecture and game lifecycle (COMPLETE — 2026-10-31)
- All tasks complete. Test results on integrated main: 46 passed, 0 failed.
- 3 chart-loader test failures resolved: laneCount=4 MVP chart + test_six_lane_chart_compatibility for 6-lane charts.
- Test coverage: hit windows PERFECT ≤50 ms (300 pts) / GOOD ≤100 ms (100 pts) / MISS >100 ms (0 pts); combo/max combo; accuracy; grade; negative-score prevention; duplicate-hit prevention; ChartLoader schema load/validate/get_notes_in_window/get_metadata incl. failure modes.

MVP-02 — Four-lane gameplay and tile spawning (CONDITIONALLY ACCEPTED — 2026-11-01)
- Implementation integrated into main at commit 2cbf5e6.
- Verification complete via MVP-02.1 (see below).
- Deferred per project owner: PlayerProfile, SaveManager, SongUnlockManager NOT integrated unless required for playable loop (ADR-016).

MVP-02.1 — Gameplay Integration & Verification (COMPLETE — 2026-11-01)
- All 8 specialist tasks complete. Test results on integrated main: 91 passed, 0 failed.
- Gameplay loop verified: Chart → Tile Spawning → Four Lanes → Touch Input → Hit Detection → Score Update.
- PlayerProfile/SaveManager/SongUnlockManager deferred (ADR-016) — not required for playable loop.

MVP-02.1 task details documented in individual agent completion reports above.

## T-MVP-02a — GameController + GameStateManager Integration
**Responsible Agent:** Agent 01 — Architecture Engineer
**Objective:** Integrate GameController and GameStateManager from architecture worktree into main to enable gameplay lifecycle management.
**Background:** These components exist in the architecture worktree but are missing from main. They are required for song preparation, state transitions, and input gating.
**Files Allowed to Change:** 
- `godot_project/scripts/core/GameController.gd` (new)
- `godot_project/scripts/core/GameStateManager.gd` (new)
- `godot_project/scripts/core/GameConfig.gd` (verify)
**Files Owned by Others:** None
**Dependencies:** None
**Expected Deliverables:**
- GameController.gd in main with prepare_song, start_song, pause_song, resume_song, complete_song, game_over, exit_to_menu
- GameStateManager.gd in main with state machine, is_playing(), is_paused(), reset_to_main_menu()
- Both registered as autoloads in project.godot (Agent 00 coordination)
**Acceptance Criteria:**
- Menu can initiate gameplay session via GameController.prepare_song()
- GameController coordinates initialization (ChartLoader → ScoreManager → AudioSync)
- Gameplay starts only after required systems ready
- Pause/resume produce valid state transitions
- Failed chart loading returns safely to menu
- No duplicate gameplay initialization
**Required Tests:** 
- Add tests/unit/test_game_controller.py (initialization, state transitions, failure handling)
- Add tests/unit/test_game_state_manager.py (state transitions, is_playing gating)
**Definition of Done:**
- [ ] Files copied from architecture worktree to main
- [ ] Autoload registration verified
- [ ] Unit tests added and passing
- [ ] Integration test: MainMenu → SongSelection → GameScene flow works (L3)
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02 Gate 1

---

## T-MVP-02b — LaneManager + NoteSpawner Integration & Verification
**Responsible Agent:** Agent 02 — Gameplay Engineer
**Objective:** Verify LaneManager and NoteSpawner in main are complete and match gameplay worktree updates; ensure 4-lane gameplay, tile spawning, hit detection, object pooling, input gating work.
**Background:** Main has LaneManager.gd and NoteSpawner.gd. Gameplay worktree has updated versions. Need to verify and integrate any improvements.
**Files Allowed to Change:**
- `godot_project/scripts/LaneManager.gd`
- `godot_project/scripts/NoteSpawner.gd`
**Files Owned by Others:**
- AudioSync.gd (Agent 03) — NoteSpawner depends on AudioSync.APPROACH_TIME
- GameScene.gd (Agent 04) — Scene wiring
- ScoreManager.gd (Agent 05) — Hit processing
**Dependencies:** T-MVP-02a (GameController for initialization), T-MVP-02c (AudioSync)
**Expected Deliverables:**
- Verified LaneManager: 4-lane config, responsive geometry, touch-to-lane mapping, input gating via GameStateManager.is_playing()
- Verified NoteSpawner: Chart-driven scheduling, audio-clock spawning, tile movement, judgment-line coordination, object pooling (MAX_POOL_LIMIT=200), missed-note handling, pool exhaustion warning
**Acceptance Criteria:**
- Exactly four lanes in MVP
- Tiles appear in assigned lanes
- Tile timing based on authoritative audio clock (AudioSync.adjusted_system_time)
- Tiles move consistently toward judgment line
- Expired notes not spawned as valid upcoming notes
- Every note resolved only once
- Object pooling: no duplicate/stale tiles, pool exhaustion logs warning
- Input disabled outside valid gameplay states (GameStateManager.is_playing())
**Required Tests:**
- Add tests/unit/test_lane_manager.py (lane geometry, touch mapping, boundaries, input gating)
- Add tests/unit/test_note_spawner.py (scheduling, spawning, movement, pooling, expiration, pool exhaustion)
**Definition of Done:**
- [ ] Main versions verified against gameplay worktree
- [ ] Any improvements merged
- [ ] Unit tests added and passing
- [ ] Integration with AudioSync verified (L3)
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02 Gate 1

---

## T-MVP-02c — AudioSync Pause/Resume + Chart Validation
**Responsible Agent:** Agent 03 — Audio Engineer
**Objective:** Verify AudioSync in main has pause/resume support, calibration integration, and ChartLoader validates 4-lane/6-lane charts correctly.
**Background:** Main has AudioSync.gd and ChartLoader.gd. Audio worktree has updates. ChartLoader tests pass (46/46).
**Files Allowed to Change:**
- `godot_project/scripts/AudioSync.gd`
- `godot_project/scripts/ChartLoader.gd`
- `godot_project/scripts/OffsetCalibration.gd`
**Files Owned by Others:**
- NoteSpawner.gd (Agent 02) — consumes AudioSync.adjusted_system_time
- ScoreManager.gd (Agent 05) — consumes AudioSync for miss detection
**Dependencies:** T-MVP-02a
**Expected Deliverables:**
- AudioSync: pause/resume without timing corruption, calibration offset applied consistently, adjusted_system_time reliable
- ChartLoader: validates laneCount, rejects invalid lane indices, supports 4-lane MVP and 6-lane compatibility
**Acceptance Criteria:**
- Note scheduling uses AudioSync not frame delta
- Pause/resume does not corrupt song position
- Calibration applied consistently
- Invalid charts cannot initialize gameplay
- Four-lane MVP charts load successfully
- Six-lane compatibility preserved
**Required Tests:**
- Add tests/unit/test_audio_sync.py (pause/resume, calibration, timing accuracy)
- ChartLoader tests already pass (verify)
**Definition of Done:**
- [ ] Main versions verified against audio worktree
- [ ] Pause/resume timing verified (L2 minimum)
- [ ] Chart validation edge cases tested
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02 Gate 1

---

## T-MVP-02d — GameScene.gd Completion (HUD, Pause, Results)
**Responsible Agent:** Agent 04 — UI/UX Engineer
**Objective:** Complete GameScene.gd to wire HUD elements, handle pause/resume, display judgment feedback, and manage results transition.
**Background:** Current GameScene.gd only initializes AudioSync. Needs full UI wiring per MVP-02 contract.
**Files Allowed to Change:**
- `godot_project/scripts/GameScene.gd`
- `godot_project/scenes/GameScene.tscn` (if HUD additions needed)
**Files Owned by Others:**
- LaneManager.gd (Agent 02) — judgment line position
- ScoreManager.gd (Agent 05) — score/combo/accuracy signals
- GameController.gd (Agent 01) — pause/resume/complete signals
- AudioSync.gd (Agent 03) — timing for judgment feedback
**Dependencies:** T-MVP-02a, T-MVP-02b, T-MVP-02e
**Expected Deliverables:**
- GameScene.gd connects to ScoreManager signals (alignment_processed, sequence_tracking_concluded)
- HUD updates: ScoreLabel, ComboLabel, RatingLabel (judgment feedback)
- PauseButton wired to GameController.pause_song()/resume_song()
- Results transition on sequence_tracking_concluded
- Judgment feedback animation (RatingLabel modulate pulse)
**Acceptance Criteria:**
- All four lanes visually distinguishable
- HUD reflects gameplay data through signals
- Pause/resume controls work through GameController
- UI does not independently manipulate scoring logic
- Layout supports different Android screen sizes
- Gameplay remains readable and responsive
**Required Tests:**
- Add tests/integration/test_gameplay_flow.py (full flow including UI updates)
**Definition of Done:**
- [ ] GameScene.gd fully implemented
- [ ] HUD wiring verified via signals
- [ ] Pause/resume functional
- [ ] Results transition works
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02 Gate 2

---

## T-MVP-02e — ScoreManager Signals + PlayerProfile Integration
**Responsible Agent:** Agent 05 — Systems Engineer
**Objective:** Verify ScoreManager signals work with GameController; integrate PlayerProfile, SaveManager, SongUnlockManager from systems worktree.
**Background:** ScoreManager.gd exists in main with signals. Systems worktree has PlayerProfile.gd, SaveManager.gd, SongUnlockManager.gd for progression compatibility.
**Files Allowed to Change:**
- `godot_project/scripts/ScoreManager.gd` (verify signals)
- `godot_project/scripts/systems/PlayerProfile.gd` (new from systems worktree)
- `godot_project/scripts/systems/SaveManager.gd` (new from systems worktree)
- `godot_project/scripts/systems/SongUnlockManager.gd` (new from systems worktree)
**Files Owned by Others:**
- GameController.gd (Agent 01) — connects ScoreManager signals
- GameScene.gd (Agent 04) — displays score/combo/accuracy
**Dependencies:** T-MVP-02a, T-MVP-02d
**Expected Deliverables:**
- ScoreManager signals connected to GameController and GameScene
- PlayerProfile autoload for offline-first persistence
- SaveManager for settings/profile serialization
- SongUnlockManager for progression compatibility (no new progression features)
**Acceptance Criteria:**
- Each valid note receives one judgment
- Invalid lane input cannot produce accidental scoring
- Missed notes counted correctly
- Score never negative
- Combo resets appropriately
- Accuracy calculations use correct denominator
- Results data retrievable by UI
- Profile persists across sessions
**Required Tests:**
- ScoreManager tests already pass (verify)
- Add tests/unit/test_player_profile.py (persistence, high scores, XP)
**Definition of Done:**
- [ ] Systems worktree components integrated to main
- [ ] Autoload registration verified
- [ ] Signal connections verified
- [ ] Persistence tested (L2)
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02 Gate 2

---

## T-MVP-02f — Gameplay Unit Tests
**Responsible Agent:** Agent 06 — QA Engineer
**Objective:** Add comprehensive gameplay unit tests for LaneManager, NoteSpawner, GameController, and integration flow.
**Background:** 46 existing tests pass. MVP-02 requires new tests for gameplay mechanics per contract.
**Files Allowed to Change:**
- `tests/unit/test_lane_manager.py` (new)
- `tests/unit/test_note_spawner.py` (new)
- `tests/unit/test_game_controller.py` (new)
- `tests/integration/test_gameplay_flow.py` (new)
- `tests/conftest.py` (fixtures as needed)
**Files Owned by Others:** None (QA owns all tests)
**Dependencies:** T-MVP-02a, T-MVP-02b (for testable implementations)
**Expected Deliverables:**
- test_lane_manager.py: 4-lane mapping, boundaries, input gating, valid/invalid states
- test_note_spawner.py: tile scheduling, note expiration, hit detection, duplicate prevention, pool reuse, pool exhaustion
- test_game_controller.py: initialization, state transitions, failure handling
- test_gameplay_flow.py: end-to-end Chart Loading → Game Initialization → Tile Scheduling → Tile Movement → Lane Input → Hit Detection → Scoring → Miss Handling
**Acceptance Criteria:**
- Existing 46 tests remain passing
- New tests meaningful and test actual behavior
- No tests weakened to pass
- Failures reported with reproduction details
- Python tests and Godot runtime tests reported separately
**Required Coverage:**
- Four-lane mapping and boundaries
- Valid/invalid chart loading (4-lane and 6-lane)
- Tile scheduling and note expiration
- Hit detection and duplicate-hit prevention
- Miss handling
- Object-pool reuse and exhaustion
- Pause/resume input gating
- Scoring integration
- Initialization failures
- State transitions
**Definition of Done:**
- [ ] All new test files created
- [ ] All tests pass (46 + new)
- [ ] Coverage targets met
- [ ] Agent 00 review PASSED
**Priority:** HIGH
**Deadline:** MVP-02 Gate 2

---

## T-MVP-02g — Android Export Readiness
**Responsible Agent:** Agent 07 — Android & Release Engineer
**Objective:** Document Android export configuration, verify export_presets.cfg, identify build dependencies.
**Background:** Android worktree has comprehensive documentation. Blocked on Godot 4 + Android SDK installation.
**Files Allowed to Change:**
- `docs/android/ANDROID_BUILD_READINESS.md`
- `docs/android/ANDROID_TEST_PLAN.md`
- `android/export_presets.cfg` (if exists)
- `project.godot` (Android-relevant fields, Agent 00 coordination)
**Files Owned by Others:**
- project.godot (Agent 00)
- godot_project/assets/textures/icon.svg (Agent 04)
**Dependencies:** B-01 (Godot 4), B-02 (Android SDK) — BLOCKED
**Expected Deliverables:**
- ANDROID_BUILD_READINESS.md (Godot/JDK/SDK requirements, export templates, env vars)
- ANDROID_TEST_PLAN.md (install, touch, audio, offline, screen-size, performance)
- Verified export_presets.cfg (package ID, permissions, orientation, signing)
**Acceptance Criteria:**
- Export config documented and internally consistent
- Build dependencies and blockers identified
- No fake APK or unverified build claims
- Debug/release signing requirements documented
**Definition of Done:**
- [ ] Documentation complete
- [ ] Export preset validated (when SDK available)
- [ ] Agent 00 review PASSED
**Priority:** MEDIUM (blocked)
**Deadline:** When SDK available

---

## T-MVP-02h — Chief Coordination + Integration Review
**Responsible Agent:** Agent 00 — Chief Engineer
**Objective:** Coordinate all specialists, enforce initialization contract, review and integrate contributions, produce integration report.
**Background:** All specialists active. Chief must verify deliverables, manage integration order, run regression tests.
**Files Allowed to Change:**
- `management/AGENT_DASHBOARD.md`
- `management/TASK_REGISTER.md`
- `management/EXECUTION_LOG.md`
- `management/INTEGRATION_LOG.md`
- `management/DECISION_REGISTER.md`
- `docs/management/ECOSYSTEM_AUDIT.md` (created)
- `docs/management/ECOSYSTEM_SETUP_REPORT.md` (to create)
- `docs/architecture/MVP02_INTEGRATION_REPORT.md` (to finalize)
**Files Owned by Others:** All (coordination only)
**Dependencies:** All specialist tasks
**Expected Deliverables:**
- Integrated main branch with all MVP-02 components
- Regression tests passing (46+)
- Integration report documenting architecture, initialization sequence, signals, technical debt
- Updated dashboard, task register, execution log
**Acceptance Criteria:**
- All seven specialists provide reviewed deliverables
- Main contains approved integrated implementation
- No unexplained merge conflicts or uncommitted changes
- Integration report identifies all remaining defects
- MVP-02 Definition of Done met
**Definition of Done:**
- [ ] All specialist integrations complete
- [ ] Regression tests pass
- [ ] Integration report complete
- [ ] MVP-02 Gate passed
**Priority:** CRITICAL
**Deadline:** MVP-02 completion

---

MVP-02.1 — Gameplay Integration & Verification (IN PROGRESS — AUTHORIZED 2026-11-01)
- Closes gaps in MVP-02: scene integration, HUD wiring, gameplay tests, timing review.
- NOT a new feature phase. Closes verification gaps only.
- Do not start MVP-03 until MVP-02.1 complete and approved.

## T-MVP-02.1a — MainMenu → GameController → GameScene Integration
**Responsible Agent:** Agent 01 — Architecture Engineer
**Objective:** Connect MainMenu Play button to GameController → GameScene so a gameplay session can actually be launched from the menu.
**Background:** GameController.gd and GameStateManager.gd exist in main but MainMenu.tscn Play button is not wired to them.
**Files Allowed to Change:**
- `godot_project/scenes/MainMenu.tscn` (scene wiring)
- `godot_project/scripts/core/GameController.gd` (verify/fix)
- `godot_project/scripts/core/GameStateManager.gd` (verify)
- `godot_project/scripts/ui/MainMenuUI.gd` (if script drives button)
**Dependencies:** T-MVP-02a (GameController exists in main)
**Expected Deliverables:**
- MainMenu Play button → GameController.prepare_song() → start_song()
- GameController initializes systems: ChartLoader → GameConfig → LaneManager → ScoreManager → NoteSpawner
- State transitions verified: MAIN_MENU → LOADING → PLAYING → PAUSED → RESULTS → MAIN_MENU
- Failed chart loading returns safely to menu
- No duplicate gameplay initialization
**Required Tests:**
- tests/unit/test_game_controller.py (initialization, state transitions, failure handling)
- tests/unit/test_game_state_manager.py (state transitions, is_playing gating)
**Definition of Done:**
- [ ] MainMenu can initiate gameplay session
- [ ] GameController initializes required systems in order
- [ ] Gameplay starts only after systems ready
- [ ] Pause/resume produce valid state transitions
- [ ] Failed chart loading returns safely to menu
- [ ] Integration test: MainMenu → GameScene flow works (L3)
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** CRITICAL
**Deadline:** MVP-02.1 Gate 1

---

## T-MVP-02.1b — GameScene.gd Completion (HUD, Pause, Results)
**Responsible Agent:** Agent 04 — UI/UX Engineer
**Objective:** Complete GameScene.gd to wire HUD elements, handle pause/resume, display judgment feedback, and manage results transition.
**Background:** Current GameScene.gd only initializes AudioSync. Needs full UI wiring per MVP-02 contract.
**Files Allowed to Change:**
- `godot_project/scripts/GameScene.gd`
- `godot_project/scenes/GameScene.tscn` (if HUD additions needed)
**Files Owned by Others:**
- LaneManager.gd (Agent 02) — judgment line position
- ScoreManager.gd (Agent 05) — score/combo/accuracy signals
- GameController.gd (Agent 01) — pause/resume/complete signals
- AudioSync.gd (Agent 03) — timing for judgment feedback
**Dependencies:** T-MVP-02.1a
**Expected Deliverables:**
- GameScene.gd connects to ScoreManager signals (alignment_processed, sequence_tracking_concluded)
- HUD updates: ScoreLabel, ComboLabel, RatingLabel (judgment feedback)
- PauseButton wired to GameController.pause_song()/resume_song()
- Results transition on sequence_tracking_concluded
- Judgment feedback animation (RatingLabel modulate pulse)
**Acceptance Criteria:**
- All four lanes visually distinguishable
- HUD reflects gameplay data through signals
- Pause/resume controls work through GameController
- UI does not independently manipulate scoring logic
- Layout supports different Android screen sizes
- Gameplay remains readable and responsive
**Required Tests:**
- tests/integration/test_gameplay_flow.py (full flow including UI updates)
**Definition of Done:**
- [ ] GameScene.gd fully implemented
- [ ] HUD wiring verified via signals
- [ ] Pause/resume functional
- [ ] Results transition works
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** CRITICAL
**Deadline:** MVP-02.1 Gate 1

---

## T-MVP-02.1c — Gameplay Unit Tests
**Responsible Agent:** Agent 06 — QA & Performance Engineer
**Objective:** Add meaningful gameplay unit tests for LaneManager, NoteSpawner, GameController, and integration flow.
**Background:** 46 existing tests pass. MVP-02.1 requires new tests for gameplay mechanics.
**Files Allowed to Change:**
- `tests/unit/test_lane_manager.py` (new)
- `tests/unit/test_note_spawner.py` (new)
- `tests/unit/test_game_controller.py` (new)
- `tests/integration/test_gameplay_flow.py` (new)
- `tests/conftest.py` (fixtures as needed)
**Files Owned by Others:** None (QA owns all tests)
**Dependencies:** T-MVP-02.1a, T-MVP-02.1b (for testable implementations)
**Expected Deliverables:**
- test_lane_manager.py: 4-lane mapping, boundaries, input gating, valid/invalid states
- test_note_spawner.py: tile scheduling, note expiration, hit detection, duplicate prevention, pool reuse, pool exhaustion
- test_game_controller.py: initialization, state transitions, failure handling
- test_gameplay_flow.py: end-to-end Chart Loading → Game Initialization → Tile Scheduling → Tile Movement → Lane Input → Hit Detection → Scoring → Miss Handling
**Acceptance Criteria:**
- Existing 46 tests remain passing
- New tests meaningful and test actual behavior
- No tests weakened to pass
- Failures reported with reproduction details
- Python tests and Godot runtime tests reported separately
**Required Coverage:**
- Four-lane mapping and boundaries
- Valid/invalid chart loading (4-lane and 6-lane)
- Tile scheduling and note expiration
- Hit detection and duplicate-hit prevention
- Miss handling
- Object-pool reuse and exhaustion
- Pause/resume input gating
- Scoring integration
- Initialization failures
- State transitions
**Definition of Done:**
- [ ] All new test files created
- [ ] All tests pass (46 + new)
- [ ] Coverage targets met
- [ ] Agent 00 review PASSED
**Priority:** CRITICAL
**Deadline:** MVP-02.1 Gate 1

---

## T-MVP-02.1d — AudioSync Timing Integration Review
**Responsible Agent:** Agent 03 — Audio & Rhythm Engineer
**Objective:** Review AudioSync and NoteSpawner timing integration. Verify AudioSync is the authoritative clock and Note scheduling uses the correct time source.
**Background:** AudioSync.gd has utility methods added (get_playback_position_seconds, is_playing, get_offset, set_offset, get_approach_time). NoteSpawner consumes adjusted_system_time.
**Files Allowed to Change:**
- `godot_project/scripts/AudioSync.gd` (verify, minimal changes only)
- `godot_project/scripts/ChartLoader.gd` (verify)
- `godot_project/scripts/OffsetCalibration.gd` (verify)
**Files Owned by Others:**
- NoteSpawner.gd (Agent 02) — consumes AudioSync.adjusted_system_time
- ScoreManager.gd (Agent 05) — consumes AudioSync for miss detection
**Dependencies:** T-MVP-02a
**Expected Deliverables:**
- Verified: AudioSync is authoritative clock (not frame delta)
- Verified: Pause/resume does not introduce timing jumps
- Verified: Calibration offsets applied consistently
- Report any unverified assumptions
**Required Tests:**
- Add tests/unit/test_audio_sync.py (pause/resume, calibration, timing accuracy)
- ChartLoader tests already pass (verify)
**Definition of Done:**
- [ ] Audio timing integration verified
- [ ] Pause/resume timing verified (L2 minimum)
- [ ] Chart validation edge cases tested
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02.1 Gate 1

---

## T-MVP-02.1e — LaneManager/NoteSpawner Review & Testable Interfaces
**Responsible Agent:** Agent 02 — Gameplay Engineer
**Objective:** Review LaneManager and NoteSpawner against gameplay requirements. Identify missing implementation beyond static source inspection.
**Background:** LaneManager.gd and NoteSpawner.gd exist in main with 4-lane config, input gating, object pooling.
**Files Allowed to Change:**
- `godot_project/scripts/LaneManager.gd` (minimal fixes only)
- `godot_project/scripts/NoteSpawner.gd` (minimal fixes only)
**Dependencies:** T-MVP-02.1a, T-MVP-02.1c
**Expected Deliverables:**
- Review report: note lifecycle, lane input, hit/miss resolution, pool reuse, input gating
- Testable interfaces exposed for QA tests
- Identify any defects requiring code changes
**Acceptance Criteria:**
- No rewrite of functioning components without defect evidence
- Lane input maps correctly to lanes
- Hit/miss resolution works exactly once
- Object pooling: no duplicate/stale tiles
- Input disabled outside valid gameplay states
**Required Tests:**
- Support Agent 06 with testable interfaces for test_lane_manager.py and test_note_spawner.py
**Definition of Done:**
- [ ] Review report completed
- [ ] Testable interfaces exposed
- [ ] Any defects identified and documented
- [ ] Agent 06 QA review PASSED
- [ ] Agent 00 integration approval
**Priority:** HIGH
**Deadline:** MVP-02.1 Gate 1

---

## T-MVP-02.1f — PlayerProfile/SaveManager/SongUnlockManager Review (DEFER unless needed)
**Responsible Agent:** Agent 05 — Game Systems Engineer
**Objective:** Review existing PlayerProfile, SaveManager and SongUnlockManager implementation. Do NOT integrate unless required for playable loop.
**Background:** These components exist in systems worktree. Per project owner directive: defer nonessential progression features.
**Files Allowed to Change:**
- None (review only, no integration unless proven necessary)
**Dependencies:** T-MVP-02.1a
**Expected Deliverables:**
- Review report: whether components are required for MVP-02.1
- Dependency correctness assessment
- Conflict check with current architecture
- Test status assessment
**Acceptance Criteria:**
- Integrate only components necessary for playable loop
- Defer nonessential progression features to later milestone
- No integration without Agent 00 approval
**Required Tests:** None (review only)
**Definition of Done:**
- [ ] Review report completed
- [ ] Integration decision documented
- [ ] Agent 00 approval for any integration
**Priority:** MEDIUM (DEFER)
**Deadline:** MVP-02.1 Gate 2

---

## T-MVP-02.1g — Android Preparation (SEPARATE from gameplay acceptance)
**Responsible Agent:** Agent 07 — Android & Release Engineer
**Objective:** Document remaining installation blockers and prepare export environment. Keep separate from gameplay acceptance.
**Background:** Android SDK and Godot 4 not installed. No APK can be generated.
**Files Allowed to Change:**
- `docs/android/ANDROID_BUILD_READINESS.md`
- `docs/android/ANDROID_TEST_PLAN.md`
**Dependencies:** B-01 (Godot 4), B-02 (Android SDK), B-04 (device)
**Expected Deliverables:**
- Documented remaining installation blockers
- Export environment preparation steps
- No fake APK or unverified build claims
**Acceptance Criteria:**
- Android preparation separate from gameplay acceptance
- No APK readiness claimed without actual successful export
- Blockers clearly identified
**Required Tests:** None (documentation only)
**Definition of Done:**
- [ ] Documentation complete
- [ ] Blockers clearly documented
- [ ] Agent 00 review PASSED
**Priority:** MEDIUM (blocked)
**Deadline:** When SDK available

---

## T-MVP-02.1h — Chief Integration + Consolidated Report
**Responsible Agent:** Agent 00 — Chief Engineer
**Objective:** Coordinate all specialists, review actual commits, integrate approved work into main, run regression suite, produce consolidated MVP-02.1 report.
**Background:** All specialists active on MVP-02.1. Chief must verify deliverables, manage integration order, run regression tests.
**Files Allowed to Change:**
- `management/AGENT_DASHBOARD.md`
- `management/TASK_REGISTER.md`
- `management/EXECUTION_LOG.md`
- `management/INTEGRATION_LOG.md`
- `management/DECISION_REGISTER.md`
- `docs/architecture/MVP02_INTEGRATION_REPORT.md`
**Dependencies:** All specialist tasks
**Expected Deliverables:**
- Integrated main branch with all MVP-02.1 components
- Regression tests passing (46+)
- Consolidated MVP-02.1 report
- Updated dashboard, task register, execution log, integration log
**Acceptance Criteria:**
- All specialist contributions reviewed and integrated
- Main contains approved integrated implementation
- No unexplained merge conflicts or uncommitted changes
- Consolidated report identifies all remaining defects
- MVP-02.1 Definition of Done met
**Definition of Done:**
- [ ] MainMenu can initiate gameplay session
- [ ] GameController initializes required gameplay systems
- [ ] Four-lane gameplay components connected
- [ ] HUD displays real gameplay data
- [ ] Pause/resume works through game lifecycle
- [ ] Results transition connected
- [ ] Gameplay tests exist and pass
- [ ] All previous 46 tests remain passing
- [ ] No critical integration defects remain
- [ ] Validation limitations honestly documented
- [ ] All specialist integrations complete
- [ ] Regression tests pass
- [ ] Consolidated MVP-02.1 report complete
- [ ] MVP-02.1 Gate passed
**Priority:** CRITICAL
**Deadline:** MVP-02.1 completion

---

---
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

## Task Status Key

| Status | Meaning |
|--------|---------|
| COMPLETE | Verified done |
| IN PROGRESS | Actively being worked |
| PENDING | Approved but not started |
| BLOCKED | Waiting on dependency or approval |

## Dependencies

- T-06..T-12 depend on T-01..T-05 (complete)
- T-MVP-02.1b..T-MVP-02.1e depend on T-MVP-02.1a (GameController/GameStateManager)
- T-MVP-02.1b depends on T-MVP-02.1d (LaneManager/NoteSpawner review)
- T-MVP-02.1c depends on T-MVP-02.1a, T-MVP-02.1b
- T-22 (APK) depends on Android SDK installation (blocked — no SDK present)
- T-23 depends on physical Android device/emulator availability (none detected)
- Wave 4 depends on MVP-02.1 COMPLETE and Agent 00 approval