# PlayerProfile.gd
# Player profile: level, XP, high scores, personal bests, statistics.
# Persisted to user://profile.dat via SaveManager. All data validated on load;
# defaults applied for missing/corrupt fields. No hardcoded secrets.
extends Node

const SAVE_PATH: String = "user://profile.dat"
const MAX_LEVEL: int = 99

var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 100
var high_scores: Dictionary = {}      # song_id -> best score (int)
var personal_bests: Dictionary = {}   # song_id -> {score, max_combo, accuracy, grade, played_at}
var statistics: Dictionary = {}       # aggregate session/all-time stats

var _save_mgr: SaveManager = null


func _enter_tree() -> void:
	_ensure_save()


func _ensure_save() -> SaveManager:
	if _save_mgr == null:
		_save_mgr = SaveManager.new()
	return _save_mgr


# ── Defaults schema (single source of truth for shape + types) ────────────
func _defaults() -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"xp_to_next_level": 100,
		"high_scores": {},
		"personal_bests": {},
		"statistics": {
			"games_played": 0,
			"total_score": 0,
			"total_perfect": 0,
			"total_good": 0,
			"total_ok": 0,
			"total_miss": 0,
			"total_notes": 0,
			"max_combo_ever": 0,
			"total_xp_earned": 0,
		},
	}


# ── Lifecycle ─────────────────────────────────────────────────────────────
func load() -> bool:
	var data := _ensure_save().load_json(SAVE_PATH, _defaults())

	level = _clamp_level(data.get("level", 1))
	xp = maxi(0, _as_int(data.get("xp", 0)))
	xp_to_next_level = maxi(1, _as_int(data.get("xp_to_next_level", 100)))
	high_scores = _validate_high_scores(data.get("high_scores", {}))
	personal_bests = _validate_personal_bests(data.get("personal_bests", {}))
	statistics = _validate_statistics(data.get("statistics", _defaults()["statistics"]))
	return true

func save() -> bool:
	var data: Dictionary = {
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level,
		"high_scores": high_scores,
		"personal_bests": personal_bests,
		"statistics": statistics,
	}
	return _ensure_save().save_json(SAVE_PATH, data)

func reset(keep_unlocked: bool = false) -> void:
	level = 1
	xp = 0
	xp_to_next_level = 100
	high_scores = {}
	personal_bests = {}
	statistics = _defaults()["statistics"].duplicate()


# ── Query API ─────────────────────────────────────────────────────────────
func get_level() -> int:
	return level

func get_xp() -> int:
	return xp

func get_xp_to_next_level() -> int:
	return xp_to_next_level

func get_high_score(song_id: String) -> int:
	return maxi(0, _as_int(high_scores.get(song_id, 0)))

func get_personal_best(song_id: String) -> Dictionary:
	var pb := personal_bests.get(song_id, {})
	return pb if typeof(pb) == TYPE_DICTIONARY else {}

func get_statistics() -> Dictionary:
	return statistics.duplicate()

func get_high_scores() -> Dictionary:
	var out: Dictionary = {}
	for k in high_scores.keys():
		out[String(k)] = maxi(0, _as_int(high_scores[k]))
	return out

func is_level_capped() -> bool:
	return level >= MAX_LEVEL


# ── Mutation API ──────────────────────────────────────────────────────────

# Add XP and level up while XP suffices. Returns a level-up summary dict.
func add_xp(amount: int) -> Dictionary:
	amount = maxi(0, _as_int(amount))
	var result: Dictionary = {
		"level_up": false,
		"new_level": level,
		"xp_gained": amount,
	}
	xp += amount
	statistics["total_xp_earned"] = _as_int(statistics.get("total_xp_earned", 0)) + amount

	while xp >= xp_to_next_level and level < MAX_LEVEL:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = _xp_for_level(level)
		result["level_up"] = true
		result["new_level"] = level
	return result

# Record a high score for a song. Returns true if a new best was set.
func record_high_score(song_id: Variant, score: Variant) -> bool:
	song_id = _validate_song_id(song_id)
	if song_id == "":
		return false
	score = maxi(0, _as_int(score))
	var current: int = maxi(0, _as_int(high_scores.get(song_id, 0)))
	if score > current:
		high_scores[song_id] = score
		return true
	return false

# Record a personal best result dict for a song. Returns true if a new best.
func record_personal_best(song_id: Variant, result: Dictionary) -> bool:
	song_id = _validate_song_id(song_id)
	if song_id == "" or typeof(result) != TYPE_DICTIONARY:
		return false
	var pb: Dictionary = {
		"score": maxi(0, _as_int(result.get("score", 0))),
		"max_combo": maxi(0, _as_int(result.get("max_combo", 0))),
		"accuracy": clampf(_as_float(result.get("accuracy", 0.0)), 0.0, 100.0),
		"grade": String(result.get("grade", "F")).substr(0, 8),
		"played_at": Time.get_datetime_string_from_system(),
	}
	var existing := personal_bests.get(song_id, {})
	if typeof(existing) != TYPE_DICTIONARY or existing == {}:
		personal_bests[song_id] = pb
		return true
	if pb["score"] > maxi(0, _as_int(existing.get("score", 0))):
		personal_bests[song_id] = pb
		return true
	return false

# Fold a completed gameplay result into profile: stats, high score, personal
# best, and XP. song_id may be empty (falls back to "unknown").
func record_gameplay_result(result: Dictionary) -> void:
	if typeof(result) != TYPE_DICTIONARY:
		return

	var score: int = maxi(0, _as_int(result.get("score", 0)))
	var max_combo: int = maxi(0, _as_int(result.get("max_combo", 0)))
	var accuracy: float = clampf(_as_float(result.get("accuracy", 0.0)), 0.0, 100.0)
	var grade: String = String(result.get("grade", "F")).substr(0, 8)
	var song_id := _validate_song_id(result.get("song_id", ""))
	if song_id == "":
		song_id = "unknown"
	var perfect: int = maxi(0, _as_int(result.get("perfect", 0)))
	var good: int = maxi(0, _as_int(result.get("good", 0)))
	var ok: int = maxi(0, _as_int(result.get("ok", 0)))
	var miss: int = maxi(0, _as_int(result.get("miss", 0)))
	var total_notes: int = maxi(0, _as_int(result.get("total_notes", 0)))

	# Aggregate statistics
	statistics["games_played"] = _as_int(statistics.get("games_played", 0)) + 1
	statistics["total_score"] = _as_int(statistics.get("total_score", 0)) + score
	statistics["total_perfect"] = _as_int(statistics.get("total_perfect", 0)) + perfect
	statistics["total_good"] = _as_int(statistics.get("total_good", 0)) + good
	statistics["total_ok"] = _as_int(statistics.get("total_ok", 0)) + ok
	statistics["total_miss"] = _as_int(statistics.get("total_miss", 0)) + miss
	statistics["total_notes"] = _as_int(statistics.get("total_notes", 0)) + total_notes
	statistics["max_combo_ever"] = maxi(_as_int(statistics.get("max_combo_ever", 0)), max_combo)

	# High score / personal best
	record_high_score(song_id, score)
	record_personal_best(song_id, {
		"score": score,
		"max_combo": max_combo,
		"accuracy": accuracy,
		"grade": grade,
	})

	# XP: 1 XP per 10 points scored
	var xp_gained: int = score // 10
	add_xp(xp_gained)


# ── Helpers ───────────────────────────────────────────────────────────────

func _validate_song_id(song_id: Variant) -> String:
	if typeof(song_id) != TYPE_STRING:
		return ""
	var s := String(song_id)
	if s.length() == 0 or s.length() > 64:
		return ""
	var valid: bool = true
	for c in s:
		var lc := c.to_lower()
		if not (c >= "0" and c <= "9" or lc >= "a" and lc <= "z" or c == "_" or c == "-"):
			valid = false
			break
	return s if valid else ""

func _clamp_level(value: Variant) -> int:
	var l := _as_int(value)
	return clampi(l, 1, MAX_LEVEL)

func _xp_for_level(l: int) -> int:
	return 100 + (l - 1) * 50

func _validate_high_scores(data: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for k in data.keys():
		var sid := _validate_song_id(k)
		if sid != "":
			out[sid] = maxi(0, _as_int(data[k]))
	return out

func _validate_personal_bests(data: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for k in data.keys():
		var sid := _validate_song_id(k)
		if sid == "":
			continue
		var v := data[k]
		if typeof(v) != TYPE_DICTIONARY:
			continue
		out[sid] = {
			"score": maxi(0, _as_int(v.get("score", 0))),
			"max_combo": maxi(0, _as_int(v.get("max_combo", 0))),
			"accuracy": clampf(_as_float(v.get("accuracy", 0.0)), 0.0, 100.0),
			"grade": String(v.get("grade", "F")).substr(0, 8),
		}
	return out

func _validate_statistics(data: Variant) -> Dictionary:
	var defaults := _defaults()["statistics"]
	var out: Dictionary = defaults.duplicate()
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for k in defaults.keys():
		if data.has(k):
			out[k] = maxi(0, _as_int(data[k]))
	return out

func _as_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT:
		return int(value)
	return 0

func _as_float(value: Variant) -> float:
	if typeof(value) == TYPE_FLOAT:
		return value
	if typeof(value) == TYPE_INT:
		return float(value)
	return 0.0
