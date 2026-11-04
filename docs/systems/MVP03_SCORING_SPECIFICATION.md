# MVP-03 Scoring Specification

**Owner:** Agent 05 — Game Systems Engineer
**Branch:** `agent/project-rhythm-systems`
**File:** `godot_project/scripts/ScoreManager.gd`
**Status:** Delivered

## 1. Scope

Refines the ScoreManager autoload singleton that owns hit-precision evaluation,
combo/score tracking, accuracy, and final statistics for a single playthrough.
Scoring logic is UI-independent (no node/UI references). All numbers are
deterministic and derived from the authoritative `AudioSync.adjusted_system_time`
clock.

## 2. Judgment windows

One-sided delta (`|playback_time − note_timestamp|`), calibrated to MVP-01
targets (3 tiers, no OK tier):

| Rating | Window | Base points | Combo |
|--------|--------|-------------|-------|
| PERFECT | delta ≤ 50 ms | 300 | +1 |
| GOOD    | delta ≤ 100 ms | 100 | +1 |
| MISS    | delta > 100 ms | 0 | reset to 0 |

Boundaries are inclusive (`<=`). A tap outside the GOOD window is ignored by
`process_action_input`; the note is auto-missed by `_process` once
`playback_time > note_timestamp + HIT_WINDOW_GOOD`.

## 3. Score multipliers

A combo-based multiplier applies to base hit points, determined by the streak
entering the hit (the combo count before this hit is added):

| Combo entering hit | Multiplier |
|--------------------|------------|
| < 10               | 1.0x |
| 10 – 24            | 1.5x |
| 25 – 49            | 2.0x |
| 50 – 99            | 2.5x |
| ≥ 100              | 3.0x |

`points = int(base_points × multiplier)`. A miss always awards 0 points and
resets the multiplier to 1.0. Score is monotonically non-decreasing and never
negative.

## 4. Accuracy

```
accuracy = resolved_notes / total_notes × 100   (0–100 %)
```

Every resolved note counts toward accuracy regardless of judgment. A miss is
still a resolved note and is counted exactly once, so a full-clear (all notes
hit or missed) yields 100% accuracy. Judgment quality is reflected in the
score, max combo, and perfect/good/miss counts — not in accuracy.

Grade bands (applied to accuracy): S ≥ 95, A ≥ 90, B ≥ 80, C ≥ 70, D ≥ 60,
F < 60.

## 5. Duplicate prevention & single counting

Each note index is tracked in `resolved_flags` (note_index → resolved bool).
All three resolution paths guard on the flag before mutating state:

- `_evaluate_hit_precision` — qualifying tap.
- `_register_miss` — auto-miss from `_process`.
- `_process` — skips any already-resolved index before auto-missing.

Therefore:
- A note is scored at most once.
- A tap on an already-resolved note is a no-op (score, combo, and resolved
  count unchanged).
- A miss and a tap cannot both resolve the same note.
- Every note is counted exactly once toward `resolved_notes_count`.

## 6. Final statistics (sequence conclusion)

When every note is resolved (`is_sequence_complete()`), `_finalize_sequence()`
runs exactly once (guarded by `sequence_completed`) and emits
`sequence_tracking_concluded` with:

- `final_score` — `absolute_accumulated_score`
- `max_combo` — `historical_maximum_combo` (peak running combo)
- `accuracy` — `get_accuracy()` (resolution-based)
- `grade` — `get_grade()` (derived from the same accuracy value)

Final statistics are mutually consistent: grade is a pure function of the
emitted accuracy, and accuracy/score/combo all derive from the same resolved
state.

## 7. Public API

- `reset_scoring_matrix(chart_payload)` — (re)initialize from chart; called by
  `GameController.prepare_song`.
- `process_action_input(target_lane)` — register a tap on a lane.
- `get_accuracy()`, `get_grade()`, `get_final_score()`, `get_max_combo()`,
  `get_combo()`, `get_combo_multiplier()`, `get_judgment_counts()`,
  `is_sequence_complete()`.

Signals:
- `alignment_processed(rating, combo, accuracy)` — per hit/miss.
- `sequence_tracking_concluded(final_score, max_combo, accuracy, grade)` —
  once at sequence end.

## 8. Verification reference

Pure-Python reference implementations live under `tests/unit/` and mirror the
judgment rules:

- `tests/unit/scoring_engine.py` — calibrated MVP-01 3-tier windows
  (PERFECT ≤ 50 ms / GOOD ≤ 100 ms / MISS > 100 ms), resolution-based
  accuracy, and the same grade bands.
- `tests/unit/test_scoring.py` — pytest suite exercising hit windows, combo,
  max-combo, accuracy, grade, negative-score prevention, duplicate-hit
  prevention, and full-chart playthroughs.

Run: `pytest tests/unit/test_scoring.py` (from the repository root).

## 9. Findings & defects corrected

1. **Accuracy was score-based, inconsistent with the reference spec.** The
   previous `get_accuracy()` returned `score / (total_notes × 300) × 100`, so
   an all-GOOD playthrough read ~33% (grade F) while the Python reference uses
   `resolved_notes / total_notes`. Corrected to resolution-based accuracy so
   grade bands (S ≥ 95, …) are meaningful and consistent with
   `scoring_engine.py` / `test_scoring.py`.

2. **No score multiplier existed.** Added a documented, deterministic combo
   multiplier (1.0x–3.0x) applied to base hit points.

3. **Duplicate scoring and single-count guarantees were implicit.** Made the
   `resolved_flags` guard explicit on every resolution path and documented the
   exactly-once semantics for hits, misses, and sequence finalization.

4. **`docs/systems/` did not exist.** Created
   `docs/systems/MVP03_SCORING_SPECIFICATION.md` (this file).

## 10. Known design notes

- Accuracy measures note resolution/completion rate, not judgment quality. As
  a consequence, a playthrough of all misses still yields 100% accuracy (every
  note resolved), matching the reference spec; judgment quality is reported via
  score and perfect/good/miss counts instead.
- The worktree `GameScene.gd` is a minimal stub and does not wire ScoreManager
  signals to a HUD; signal consumers are expected to connect at their own
  composition root.
