# ScoreManager.gd
# Autoload Singleton — hit precision evaluation and combo/score tracking.
#
# Gameplay logic only; independent of the UI layer. Agent 02 (gameplay) calls
# this API; Agent 04 (UI) reads results via signals/getters.
#
# Judgment windows (one-sided delta from note timestamp):
#   PERFECT : ≤ 50 ms   → 300 pts
#   GOOD    : ≤ 100 ms  → 100 pts
#   MISS    : > 100 ms  →   0 pts, combo reset
#
# Notes that are never hit and drift past +100 ms are auto-missed in _process().
#
# Scoring model:
#   multiplier = clamp(1 + floor(combo / 10), 1, MAX_MULTIPLIER)
#   points     = base_points * multiplier   (applied at the moment of the hit)
#   score      = sum(points) over the song
#   accuracy   = hit_notes / total_notes * 100
#   grade      = derived from accuracy (S / A / B / C / D / F)
extends Node

# ── Judgment windows (seconds) ────────────────────────────────────────────
const JUDGMENT_PERFECT_MS: float = 0.050
const JUDGMENT_GOOD_MS: float = 0.100
const HIT_MATCH_BOUND_MS: float = 0.100  # outer bound to attempt a lane match

# ── Base points per rating ────────────────────────────────────────────────
const SCORE_PERFECT: int = 300
const SCORE_GOOD: int = 100
const SCORE_MISS: int = 0

# ── Combo multiplier ──────────────────────────────────────────────────────
const COMBO_MULTIPLIER_STEP: int = 10  # +1 multiplier every 10 combo
const MAX_MULTIPLIER: int = 4

# ── Grade thresholds (accuracy %) ─────────────────────────────────────────
const GRADE_S: float = 95.0
const GRADE_A: float = 90.0
const GRADE_B: float = 80.0
const GRADE_C: float = 70.0
const GRADE_D: float = 60.0

# ── Signals (UI / gameplay consume these) ─────────────────────────────────
signal alignment_processed(rating: String, combo: int)
signal hit_evaluated(rating: String, combo: int, points: int, multiplier: int, score: int)
signal combo_broken(combo: int)
signal sequence_tracking_concluded(final_score: int, max_combo: int)
signal sequence_concluded(results: Dictionary)

# ── Session state ─────────────────────────────────────────────────────────
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var multiplier: int = 1

var perfect_count: int = 0
var good_count: int = 0
var miss_count: int = 0
var total_notes: int = 0

var reference_timeline: Array = []
var resolved_flags: Dictionary = {}  # note_index (int) → resolved (bool)

var _resolved_count: int = 0
var _song_concluded: bool = false


func reset_scoring_matrix(chart_payload: Dictionary) -> void:
	score = 0
	combo = 0
	max_combo = 0
	multiplier = 1
	perfect_count = 0
	good_count = 0
	miss_count = 0
	total_notes = 0
	_resolved_count = 0
	_song_concluded = false

	reference_timeline = chart_payload.get("noteTimeline", [])
	if typeof(reference_timeline) != TYPE_ARRAY:
		reference_timeline = []
	total_notes = reference_timeline.size()

	resolved_flags.clear()
	for i in range(reference_timeline.size()):
		resolved_flags[i] = false


# ── Input: Agent 02 calls this on each lane tap ───────────────────────────
func process_action_input(target_lane: int) -> void:
	if typeof(target_lane) != TYPE_INT:
		return

	var playback_time: float = AudioSync.adjusted_system_time
	var best_index: int = -1
	var best_delta: float = 999.9

	for i in range(reference_timeline.size()):
		if resolved_flags.has(i) and resolved_flags[i]:
			continue
		var note: Dictionary = reference_timeline[i]
		if typeof(note) != TYPE_DICTIONARY:
			continue
		if note.get("lane", -1) != target_lane:
			continue
		var delta: float = absf(playback_time - float(note.get("timestamp", 0.0)))
		if delta < best_delta:
			best_delta = delta
			best_index = i

	if best_index != -1 and best_delta <= HIT_MATCH_BOUND_MS:
		_evaluate_hit_precision(best_index, best_delta)
	else:
		_register_miss()


# ── Pure hit evaluation (no state mutation) — usable by gameplay/tests ────
func evaluate_judgment(error_delta: float) -> Dictionary:
	var result: Dictionary = {
		"rating": "MISS",
		"base_points": 0,
		"is_hit": false,
	}
	if error_delta <= JUDGMENT_PERFECT_MS:
		result["rating"] = "PERFECT"
		result["base_points"] = SCORE_PERFECT
		result["is_hit"] = true
	elif error_delta <= JUDGMENT_GOOD_MS:
		result["rating"] = "GOOD"
		result["base_points"] = SCORE_GOOD
		result["is_hit"] = true
	return result


func _evaluate_hit_precision(note_index: int, error_delta: float) -> void:
	resolved_flags[note_index] = true
	_resolved_count += 1

	var judgment := evaluate_judgment(error_delta)
	var rating: String = judgment["rating"]
	var base_points: int = judgment["base_points"]

	if rating == "MISS":
		combo = 0
		multiplier = 1
		miss_count += 1
		emit_signal("alignment_processed", "MISS", 0)
		emit_signal("hit_evaluated", "MISS", 0, 0, 1, score)
		emit_signal("combo_broken", 0)
		_try_conclude()
		return

	perfect_count = perfect_count + (1 if rating == "PERFECT" else 0)
	good_count = good_count + (1 if rating == "GOOD" else 0)

	combo += 1
	max_combo = maxi(max_combo, combo)
	multiplier = _compute_multiplier(combo)
	var points: int = base_points * multiplier
	score += points

	emit_signal("alignment_processed", rating, combo)
	emit_signal("hit_evaluated", rating, combo, points, multiplier, score)
	_try_conclude()


func _register_miss() -> void:
	combo = 0
	multiplier = 1
	miss_count += 1
	_resolved_count += 1
	emit_signal("alignment_processed", "MISS", 0)
	emit_signal("hit_evaluated", "MISS", 0, 0, 1, score)
	emit_signal("combo_broken", 0)
	_try_conclude()


func _try_conclude() -> void:
	if _song_concluded:
		return
	if reference_timeline.size() > 0 and _resolved_count >= reference_timeline.size():
		_song_concluded = true
		_emit_conclusion()


# ── Auto-miss notes that drift past the hit window ────────────────────────
func _process(_delta: float) -> void:
	if not AudioSync.active_playback_flag:
		return

	var playback_time: float = AudioSync.adjusted_system_time
	for i in range(reference_timeline.size()):
		if resolved_flags.has(i) and resolved_flags[i]:
			continue
		var note: Dictionary = reference_timeline[i]
		if typeof(note) != TYPE_DICTIONARY:
			continue
		# Auto-miss notes that have drifted 100 ms past their hit window
		if playback_time > float(note.get("timestamp", 0.0)) + JUDGMENT_GOOD_MS:
			resolved_flags[i] = true
			_register_miss()

	if not _song_concluded and reference_timeline.size() > 0 and _resolved_count >= reference_timeline.size():
		_song_concluded = true
		_emit_conclusion()


# ── Query API (read-only, UI-safe) ────────────────────────────────────────
func get_score() -> int:
	return score

func get_combo() -> int:
	return combo

func get_max_combo() -> int:
	return max_combo

func get_multiplier() -> int:
	return multiplier

func get_accuracy() -> float:
	if total_notes == 0:
		return 0.0
	var hits: int = perfect_count + good_count
	return clampf(float(hits) / float(total_notes) * 100.0, 0.0, 100.0)

func get_grade() -> String:
	var acc: float = get_accuracy()
	if acc >= GRADE_S:
		return "S"
	if acc >= GRADE_A:
		return "A"
	if acc >= GRADE_B:
		return "B"
	if acc >= GRADE_C:
		return "C"
	if acc >= GRADE_D:
		return "D"
	return "F"

func get_final_score() -> int:
	return score

func get_stats() -> Dictionary:
	return {
		"score": score,
		"combo": combo,
		"max_combo": max_combo,
		"multiplier": multiplier,
		"accuracy": get_accuracy(),
		"grade": get_grade(),
		"perfect": perfect_count,
		"good": good_count,
		"miss": miss_count,
		"total_notes": total_notes,
	}

func is_song_concluded() -> bool:
	return _song_concluded


# ── Internal ──────────────────────────────────────────────────────────────
func _compute_multiplier(current_combo: int) -> int:
	return clampi(1 + (current_combo // COMBO_MULTIPLIER_STEP), 1, MAX_MULTIPLIER)

func _emit_conclusion() -> void:
	var results: Dictionary = get_stats()
	results["final_score"] = score
	emit_signal("sequence_tracking_concluded", score, max_combo)
	emit_signal("sequence_concluded", results)
