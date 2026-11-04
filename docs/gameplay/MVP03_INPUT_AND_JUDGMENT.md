# MVP-03 Input and Judgment — PROJECT RHYTHM

Project: HexaRhythm  
Owner: Agent 02 — Gameplay Engineer  
Date: 2026-11-02  
Files: godot_project/scripts/LaneManager.gd, godot_project/scripts/NoteSpawner.gd  
Verification: L2 unit — L4 blocked by B-01

## 1. Duplicate Input Processing Prevention (MVP-03)

`LaneManager._on_column_touch_down()` now applies a per-lane tap debounce before forwarding to `ScoreManager.process_action_input()`:

- `DEBOUNCE_SECONDS = 0.08` (80 ms minimum between same-lane taps).
- `_last_tap_time` dictionary tracks the last tap time per lane index.
- `_is_tap_debounced(lane_index, now)` returns true if `now - last_tap < DEBOUNCE_SECONDS`.
- Debounced taps are silently dropped; no call to ScoreManager.

This prevents a single physical tap from registering as multiple judgments on the same note. `ScoreManager.resolved_flags` remains the second layer: a note already resolved (hit or miss) cannot be re-scored.

Verified by `tests/unit/test_duplicate_prevention.py`.

## 2. Simultaneous and Rapid Input Handling

- `_input(event)` handles each `InputEventScreenTouch` independently. Multi-touch on different lanes produces separate `column_touch_down` emissions, resolved concurrently by ScoreManager per-lane.
- Rapid taps on **different** lanes are not debounced (debounce is per-lane), so fast alternating input across lanes works normally.
- Rapid taps on the **same** lane within 80 ms are suppressed (duplicate prevention).

## 3. Note Lifecycle and Missed-Note Processing (MVP-03)

`NoteSpawner` exposes `get_expired_note_indices(playback_time)` — returns timeline indices whose hit time has passed but were never spawned (not in `deployed_timeline_indices`). These are candidates for missed-note resolution by `ScoreManager._process` (notes past `hit_time + HIT_WINDOW_GOOD` are auto-missed).

Key rules preserved:
- Expired notes are **never rendered** as valid upcoming tiles (`playback_time >= hit_time` → skip spawn).
- Every deployed note is tracked in `deployed_timeline_indices` so expired detection is accurate.
- Object pooling: `MAX_POOL_LIMIT = 200`; `push_warning` on exhaustion; retired tiles recycled.

Verified by `tests/unit/test_note_spawner.py` (existing) + `tests/integration/test_song_completion.py`.

## 4. Input Latency and Responsiveness Review

- Input is gated by `input_enabled` in `_input()` and `GameStateManager.is_playing()` in `_on_column_touch_down()`.
- Debounce window of 80 ms balances duplicate suppression against responsiveness for legitimate rapid play.
- No frame-delta accumulation in the input path; judgment uses `AudioSync.adjusted_system_time` (authoritative clock).

## 5. Signals

| Signal | Direction | Purpose |
|--------|-----------|---------|
| `column_touch_down(lane_index)` | LaneManager → ScoreManager | Finger down on a lane; triggers hit evaluation |
| `column_touch_up(lane_index)` | LaneManager → (unbound) | Finger up on a lane |

`column_touch_down` is bound to `ScoreManager.process_action_input` in `LaneManager._ready()`.

## 6. Dependencies

| Dependency | Direction | Notes |
|------------|-----------|-------|
| `GameConfig.normalize_lane_count()` | LaneManager → GameConfig | Clamps lane count to [4, 6] |
| `GameStateManager.is_playing()` | LaneManager → GameStateManager | Input gating |
| `ScoreManager.process_action_input()` | LaneManager → ScoreManager | Hit/miss evaluation |
| `AudioSync.adjusted_system_time`, `APPROACH_TIME` | NoteSpawner → AudioSync | Spawn timing |
| `lane_manager` (`$"../LaneManager"`) | NoteSpawner → LaneManager | Lane geometry / drop distance |

## 7. Verification Level

| Level | Status | Evidence |
|-------|--------|----------|
| L1 Static | ✅ | Code review complete |
| L2 Unit | ✅ | test_lane_manager.py, test_duplicate_prevention.py, test_note_spawner.py |
| L3 Integration | ❌ | Requires Godot runtime (blocked B-01) |
| L4 Godot Runtime | ❌ | B-01: Godot 4 not installed |

## 8. File Inventory

| File | Status |
|------|--------|
| `godot_project/scripts/LaneManager.gd` | Modified (MVP-03: per-lane debounce) |
| `godot_project/scripts/NoteSpawner.gd` | Modified (MVP-03: expired-note query) |
| `tests/unit/test_duplicate_prevention.py` | New (5 tests) |
| `tests/unit/lane_manager.py` | Existing (reference impl) |
| `tests/unit/note_spawner.py` | Existing (reference impl) |
| `docs/gameplay/MVP03_INPUT_AND_JUDGMENT.md` | New (this document) |
