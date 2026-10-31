# ScoreManager.gd
# Autoload Singleton — hit precision evaluation and combo/score tracking.
#
# Judgment windows (one-sided delta from note timestamp):
#   PERFECT : ≤ 45 ms   → 300 pts
#   GOOD    : ≤ 90 ms   → 100 pts
#   OK      : ≤ 150 ms  →  50 pts
#   MISS    : > 150 ms  →   0 pts, combo reset
#
# Notes that are never hit and drift past +150 ms are auto-missed in _process().
extends Node

signal alignment_processed(rating: String, combo: int)
signal sequence_tracking_concluded(final_score: int, max_combo: int)

var absolute_accumulated_score: int = 0
var operational_combo_counter: int = 0
var historical_maximum_combo: int = 0

var reference_timeline: Array = []
var resolved_flags: Dictionary = {}   # note_index (int) → resolved (bool)


func reset_scoring_matrix(chart_payload: Dictionary) -> void:
	absolute_accumulated_score = 0
	operational_combo_counter = 0
	historical_maximum_combo = 0
	reference_timeline = chart_payload["noteTimeline"]
	resolved_flags.clear()
	for i: int in range(reference_timeline.size()):
		resolved_flags[i] = false


func process_action_input(target_lane: int) -> void:
	var playback_time: float = AudioSync.adjusted_system_time
	var best_index: int = -1
	var best_delta: float = 999.9

	for i: int in range(reference_timeline.size()):
		if resolved_flags[i]:
			continue
		var note: Dictionary = reference_timeline[i]
		if note["lane"] != target_lane:
			continue
		var delta: float = absf(playback_time - note["timestamp"])
		if delta < best_delta:
			best_delta = delta
			best_index = i

	if best_index != -1 and best_delta <= 0.180:
		_evaluate_hit_precision(best_index, best_delta)
	else:
		_register_miss()


func _evaluate_hit_precision(note_index: int, error_delta: float) -> void:
	resolved_flags[note_index] = true
	var rating: String
	var points: int

	if error_delta <= 0.045:
		rating = "PERFECT"
		points = 300
		operational_combo_counter += 1
	elif error_delta <= 0.090:
		rating = "GOOD"
		points = 100
		operational_combo_counter += 1
	elif error_delta <= 0.150:
		rating = "OK"
		points = 50
		operational_combo_counter += 1
	else:
		rating = "MISS"
		points = 0
		operational_combo_counter = 0

	absolute_accumulated_score += points
	historical_maximum_combo = maxi(historical_maximum_combo, operational_combo_counter)
	emit_signal("alignment_processed", rating, operational_combo_counter)


func _register_miss() -> void:
	operational_combo_counter = 0
	emit_signal("alignment_processed", "MISS", 0)


func _process(_delta: float) -> void:
	if not AudioSync.active_playback_flag:
		return

	var playback_time: float = AudioSync.adjusted_system_time

	for i: int in range(reference_timeline.size()):
		if resolved_flags[i]:
			continue
		var note: Dictionary = reference_timeline[i]
		# Auto-miss notes that have drifted 150 ms past their hit window
		if playback_time > note["timestamp"] + 0.150:
			resolved_flags[i] = true
			_register_miss()

	# Emit final score when the last note resolves
	if AudioSync.active_playback_flag == false:
		emit_signal(
			"sequence_tracking_concluded",
			absolute_accumulated_score,
			historical_maximum_combo
		)
