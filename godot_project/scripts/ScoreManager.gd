# ScoreManager.gd
# Autoload Singleton — hit precision evaluation and combo/score tracking.
# Scoring logic is UI-independent (no references to nodes/UI).
#
# Judgment windows (one-sided delta from note timestamp):
#   PERFECT : <= 50 ms  -> 300 pts, combo +1
#   GOOD    : <= 100 ms -> 100 pts, combo +1
#   MISS    : > 100 ms  ->   0 pts, combo reset, note resolved once
#
# MVP-03 scoring refinement:
#   - Combo-based score multiplier (tiers: 1x/2x/3x/4x, capped at 4x).
#   - Accuracy reflects timing precision (judgment-based), not multiplier.
#   - Each note resolved exactly once (resolved_flags); duplicate hits are no-ops.
#   - Score never negative; miss resets running combo; max combo tracks peak.
#   - Final statistics (score, max_combo, accuracy, grade, counts) are consistent.
#
# Accuracy = (perfect*300 + good*100) / (total_notes * 300) * 100   (0-100 %)
# Grade bands: S >= 95, A >= 90, B >= 80, C >= 70, D >= 60, F < 60
# Multiplier tiers: 0-9 combo = 1x, 10-19 = 2x, 20-29 = 3x, 30+ = 4x (cap)

extends Node

signal alignment_processed(rating: String, combo: int, accuracy: float)
signal sequence_tracking_concluded(final_score: int, max_combo: int, accuracy: float, grade: String)

const MAX_POINTS_PER_NOTE: int = 300
const MAX_MULTIPLIER: int = 4
const COMBO_TIER_STEP: int = 10

# Difficulty score multipliers (applied to base points).
const DIFFICULTY_EASY: float = 0.7
const DIFFICULTY_NORMAL: float = 1.0
const DIFFICULTY_HARD: float = 1.4
const DIFFICULTY_EXPERT: float = 2.0

# Hold note scoring: longer holds earn more points, capped at 3x.
const HOLD_BASE_POINTS: int = 300
const HOLD_DURATION_DIVISOR: float = 0.5  # seconds for 1x; clamp to [1.0, 3.0]
const HOLD_MAX_MULTIPLIER: float = 3.0

const GRADE_S: String = "S"
const GRADE_A: String = "A"
const GRADE_B: String = "B"
const GRADE_C: String = "C"
const GRADE_D: String = "D"
const GRADE_F: String = "F"

var absolute_accumulated_score: int = 0
var operational_combo_counter: int = 0
var historical_maximum_combo: int = 0
var total_note_count: int = 0
var resolved_notes_count: int = 0
var sequence_completed: bool = false

var perfect_count: int = 0
var good_count: int = 0
var miss_count: int = 0

var reference_timeline: Array = []
var resolved_flags: Dictionary = {}   # note_index (int) -> resolved (bool)


func reset_scoring_matrix(chart_payload: Dictionary) -> void:
	absolute_accumulated_score = 0
	operational_combo_counter = 0
	historical_maximum_combo = 0
	resolved_notes_count = 0
	perfect_count = 0
	good_count = 0
	miss_count = 0
	sequence_completed = false
	reference_timeline = chart_payload.get("noteTimeline", [])
	if typeof(reference_timeline) != TYPE_ARRAY:
		reference_timeline = []
	resolved_flags.clear()
	for i: int in range(reference_timeline.size()):
		resolved_flags[i] = false
	total_note_count = reference_timeline.size()


# ── Multiplier ────────────────────────────────────────────────────────────────

# Existing combo-based multiplier (backward-compatible, no arguments).
func get_multiplier() -> int:
	"""Combo-based score multiplier. Tiers: 1x/2x/3x/4x, capped at MAX_MULTIPLIER."""
	var tier: int = 1 + int(operational_combo_counter / COMBO_TIER_STEP)
	return clampi(tier, 1, MAX_MULTIPLIER)


# Difficulty score multiplier.
func get_difficulty_multiplier(difficulty: String = "") -> float:
	"""Difficulty score multiplier.

	EASY=0.7, NORMAL=1.0, HARD=1.4, EXPERT=2.0. Unknown/empty defaults to NORMAL.
	"""
	var d: String = difficulty.to_upper()
	match d:
		"EASY": return DIFFICULTY_EASY
		"HARD": return DIFFICULTY_HARD
		"EXPERT": return DIFFICULTY_EXPERT
		_: return DIFFICULTY_NORMAL


# Combined score multiplier: combo tier * difficulty.
func get_total_multiplier(difficulty: String = "") -> float:
	"""Combined score multiplier: combo tier * difficulty."""
	return float(get_multiplier()) * get_difficulty_multiplier(difficulty)


# ── Queries ───────────────────────────────────────────────────────────────────

func get_accuracy() -> float:
	"""Timing-precision accuracy: judgment quality / theoretical max, 0-100 %."""
	if total_note_count <= 0:
		return 0.0
	var earned: float = float(perfect_count) * float(MAX_POINTS_PER_NOTE) + float(good_count) * 100.0
	var max_possible: float = float(total_note_count) * float(MAX_POINTS_PER_NOTE)
	var accuracy: float = earned / max_possible * 100.0
	return clampf(accuracy, 0.0, 100.0)


func get_grade() -> String:
	var accuracy: float = get_accuracy()
	if accuracy >= 95.0:
		return GRADE_S
	if accuracy >= 90.0:
		return GRADE_A
	if accuracy >= 80.0:
		return GRADE_B
	if accuracy >= 70.0:
		return GRADE_C
	if accuracy >= 60.0:
		return GRADE_D
	return GRADE_F


func get_final_score() -> int:
	return absolute_accumulated_score


func get_score() -> int:
	return absolute_accumulated_score


func get_perfect_count() -> int:
	return perfect_count


func get_good_count() -> int:
	return good_count


func get_miss_count() -> int:
	return miss_count


func get_max_combo() -> int:
	return historical_maximum_combo


func get_combo() -> int:
	return operational_combo_counter


func get_judgment_counts() -> Dictionary:
	return {
		"perfect": perfect_count,
		"good": good_count,
		"miss": miss_count,
	}


func is_sequence_complete() -> bool:
	if total_note_count <= 0:
		return true
	for i: int in range(reference_timeline.size()):
		if not resolved_flags.get(i, false):
			return false
	return true


# ── Input ─────────────────────────────────────────────────────────────────────

func process_action_input(target_lane: int, difficulty: String = "") -> void:
	if reference_timeline.is_empty():
		return
	if target_lane < 0 or target_lane >= GameConfig.normalize_lane_count(GameConfig.DEFAULT_LANE_COUNT):
		return

	var playback_time: float = AudioSync.adjusted_system_time
	var best_index: int = -1
	var best_delta: float = 999.9

	for i: int in range(reference_timeline.size()):
		if resolved_flags.get(i, false):
			continue
		var note: Dictionary = reference_timeline[i]
		if int(note.get("lane", -1)) != target_lane:
			continue
		var timestamp: float = float(note.get("timestamp", 0.0))
		var delta: float = absf(playback_time - timestamp)
		if delta < best_delta:
			best_delta = delta
			best_index = i

	if best_index == -1:
		return
	# Only taps within the GOOD window count as a hit; off-window taps are ignored
	# and the note is auto-missed by _process once the window expires.
	if best_delta <= AudioSync.get_judgment_window_good():
		_evaluate_hit_precision(best_index, best_delta, difficulty)


func _evaluate_hit_precision(note_index: int, error_delta: float, difficulty: String = "") -> void:
	if resolved_flags.get(note_index, false):
		return

	resolved_flags[note_index] = true
	resolved_notes_count += 1
	var rating: String
	var base_points: int

	if error_delta <= AudioSync.get_judgment_window_perfect():
		rating = "PERFECT"
		base_points = 300
		perfect_count += 1
		operational_combo_counter += 1
	elif error_delta <= AudioSync.get_judgment_window_good():
		rating = "GOOD"
		base_points = 100
		good_count += 1
		operational_combo_counter += 1
	else:
		rating = "MISS"
		base_points = 0
		miss_count += 1
		operational_combo_counter = 0

	var difficulty_mult: float = get_difficulty_multiplier(difficulty)
	var points: int = int(float(base_points) * float(get_multiplier()) * difficulty_mult)
	absolute_accumulated_score += points
	historical_maximum_combo = maxi(historical_maximum_combo, operational_combo_counter)
	emit_signal("alignment_processed", rating, operational_combo_counter, get_accuracy())
	if is_sequence_complete() and not sequence_completed:
		_finalize_sequence()


# ── Extended input: hold notes and chords ───────────────────────────────────

# Evaluate a completed hold note. Points accumulate with hold duration and are
# scaled by the combo and difficulty multipliers. Returns {rating, points}.
func process_hold_note(note_index: int, hold_duration_seconds: float, difficulty: String = "") -> Dictionary:
	var result: Dictionary = {
		"rating": "MISS",
		"points": 0,
	}
	if note_index < 0 or note_index >= reference_timeline.size():
		return result
	if resolved_flags.get(note_index, false):
		return result

	var hold_duration: float = maxi(0.0, float(hold_duration_seconds))
	var hold_mult: float = clampf(hold_duration / HOLD_DURATION_DIVISOR, 1.0, HOLD_MAX_MULTIPLIER)

	resolved_flags[note_index] = true
	resolved_notes_count += 1
	operational_combo_counter += 1
	perfect_count += 1

	var points: int = int(float(HOLD_BASE_POINTS) * hold_mult * float(get_multiplier()) * get_difficulty_multiplier(difficulty))
	absolute_accumulated_score += points
	historical_maximum_combo = maxi(historical_maximum_combo, operational_combo_counter)

	result["rating"] = "PERFECT"
	result["points"] = points
	emit_signal("alignment_processed", "PERFECT", operational_combo_counter, get_accuracy())
	if is_sequence_complete() and not sequence_completed:
		_finalize_sequence()
	return result


# Evaluate a simultaneous chord hit. Each note scores independently from its
# rating; the combo counts only once for the whole chord. Returns total points.
func process_chord_hit(note_indices: Array, ratings: Array, difficulty: String = "") -> int:
	if typeof(note_indices) != TYPE_ARRAY or typeof(ratings) != TYPE_ARRAY:
		return 0
	if note_indices.size() == 0:
		return 0

	var total_base: int = 0
	var newly_resolved: int = 0

	for i: int in range(note_indices.size()):
		var idx: int = int(note_indices[i])
		if idx < 0 or idx >= reference_timeline.size():
			continue
		if resolved_flags.get(idx, false):
			continue
		var rating: String = str(ratings.get(i, "MISS")).to_upper()
		var base: int = 0
		match rating:
			"PERFECT": base = 300; perfect_count += 1
			"GOOD": base = 100; good_count += 1
			"OK": base = 50
			"MISS": base = 0; miss_count += 1
			_: base = 0; miss_count += 1
		total_base += base
		resolved_flags[idx] = true
		resolved_notes_count += 1
		newly_resolved += 1

	# Combo counts once for the chord.
	if newly_resolved > 0:
		operational_combo_counter += 1

	var difficulty_mult: float = get_difficulty_multiplier(difficulty)
	var total_points: int = int(float(total_base) * float(get_multiplier()) * difficulty_mult)
	absolute_accumulated_score += total_points
	historical_maximum_combo = maxi(historical_maximum_combo, operational_combo_counter)

	emit_signal("alignment_processed", "CHORD", operational_combo_counter, get_accuracy())
	if is_sequence_complete() and not sequence_completed:
		_finalize_sequence()
	return total_points


func _register_miss(note_index: int) -> void:
	if resolved_flags.get(note_index, false):
		return
	resolved_flags[note_index] = true
	resolved_notes_count += 1
	miss_count += 1
	operational_combo_counter = 0
	emit_signal("alignment_processed", "MISS", 0, get_accuracy())
	if is_sequence_complete() and not sequence_completed:
		_finalize_sequence()


func _finalize_sequence() -> void:
	sequence_completed = true
	emit_signal(
		"sequence_tracking_concluded",
		absolute_accumulated_score,
		historical_maximum_combo,
		get_accuracy(),
		get_grade()
	)


func _process(_delta: float) -> void:
	if reference_timeline.is_empty():
		return
	if not AudioSync.active_playback_flag:
		if is_sequence_complete() and not sequence_completed:
			_finalize_sequence()
		return

	var playback_time: float = AudioSync.adjusted_system_time
	for i: int in range(reference_timeline.size()):
		if resolved_flags.get(i, false):
			continue
		var note: Dictionary = reference_timeline[i]
		var note_time: float = float(note.get("timestamp", 0.0))
		if playback_time > note_time + AudioSync.get_judgment_window_good():
			_register_miss(i)
	if is_sequence_complete() and not sequence_completed:
		_finalize_sequence()
