# PlayerProfile.gd
# Autoload Singleton — offline-first player profile persistence (user://).
#
# Persists: level, XP, per-song high scores / personal bests, song unlock
# states, play statistics, achievements, daily-reward state.
#
# All persisted data is validated on load; defaults are applied for missing or
# corrupt fields. No secrets are stored.

extends Node

signal profile_loaded
signal profile_saved
signal high_score_updated(song_id: String, score: int)
signal song_unlocked(song_id: String)
signal level_up(new_level: int)

const PROFILE_PATH: String = "user://profile.cfg"

var _profile: Dictionary = {
	"level": 1,
	"xp": 0,
	"xp_to_next": 100,
	"total_score": 0,
	"plays": 0,
	"perfects": 0,
	"goods": 0,
	"misses": 0,
	"max_combo_ever": 0,
	"high_scores": {},
	"best_accuracy": {},
	"result_history": [],
	"song_unlocks": {},
	"achievements": {},
	"daily": {
		"last_reward_date": "",
		"streak": 0,
	},
}

var _dirty: bool = false


func _ready() -> void:
	load_profile()


func load_profile() -> Dictionary:
	var config := ConfigFile.new()
	var err: Error = config.load(PROFILE_PATH)
	if err != OK:
		_profile = _default_profile()
		emit_signal("profile_loaded", _profile.duplicate())
		return _profile.duplicate()

	var raw_level: int = int(config.get_value("profile", "level", 1))
	var raw_xp: int = int(config.get_value("profile", "xp", 0))
	var raw_xp_to_next: int = int(config.get_value("profile", "xp_to_next", 100))
	var raw_total_score: int = int(config.get_value("profile", "total_score", 0))
	var raw_plays: int = int(config.get_value("profile", "plays", 0))
	var raw_perfects: int = int(config.get_value("profile", "perfects", 0))
	var raw_goods: int = int(config.get_value("profile", "goods", 0))
	var raw_misses: int = int(config.get_value("profile", "misses", 0))
	var raw_max_combo: int = int(config.get_value("profile", "max_combo_ever", 0))

	# Clamp to non-negative.
	raw_level = maxi(1, raw_level)
	raw_xp = maxi(0, raw_xp)
	raw_xp_to_next = maxi(1, raw_xp_to_next)
	raw_total_score = maxi(0, raw_total_score)
	raw_plays = maxi(0, raw_plays)
	raw_perfects = maxi(0, raw_perfects)
	raw_goods = maxi(0, raw_goods)
	raw_misses = maxi(0, raw_misses)
	raw_max_combo = maxi(0, raw_max_combo)

	var high_scores: Dictionary = {}
	var raw_scores: Variant = config.get_value("scores", "high_scores", {})
	if typeof(raw_scores) == TYPE_DICTIONARY:
		for key: Variant in raw_scores.keys():
			var song_id: String = str(key)
			var score: int = maxi(0, int(raw_scores[key]))
			high_scores[song_id] = score
	var best_accuracy: Dictionary = {}
	var raw_accuracy: Variant = config.get_value("scores", "best_accuracy", {})
	if typeof(raw_accuracy) == TYPE_DICTIONARY:
		for key: Variant in raw_accuracy.keys():
			var accuracy := float(raw_accuracy[key])
			best_accuracy[str(key)] = clampf(accuracy, 0.0, 100.0) if is_finite(accuracy) else 0.0
	var raw_history: Variant = config.get_value("history", "results", [])
	var result_history: Array = raw_history.slice(maxi(0, raw_history.size() - 100)) if raw_history is Array else []

	var song_unlocks: Dictionary = {}
	var raw_unlocks: Variant = config.get_value("progression", "song_unlocks", {})
	if typeof(raw_unlocks) == TYPE_DICTIONARY:
		for key: Variant in raw_unlocks.keys():
			var song_id: String = str(key)
			song_unlocks[song_id] = bool(raw_unlocks[key])

	var achievements: Dictionary = {}
	var raw_ach: Variant = config.get_value("achievements", "achievements", {})
	if typeof(raw_ach) == TYPE_DICTIONARY:
		for key: Variant in raw_ach.keys():
			var ach_id: String = str(key)
			var entry: Dictionary = _default_achievement_entry()
			var raw_entry: Variant = raw_ach[key]
			if typeof(raw_entry) == TYPE_DICTIONARY:
				entry["unlocked"] = bool(raw_entry.get("unlocked", false))
				entry["progress"] = maxi(0, int(raw_entry.get("progress", 0)))
			achievements[ach_id] = entry

	var daily: Dictionary = {
		"last_reward_date": str(config.get_value("daily", "last_reward_date", "")),
		"streak": maxi(0, int(config.get_value("daily", "streak", 0))),
	}

	_profile = {
		"level": raw_level,
		"xp": raw_xp,
		"xp_to_next": raw_xp_to_next,
		"total_score": raw_total_score,
		"plays": raw_plays,
		"perfects": raw_perfects,
		"goods": raw_goods,
		"misses": raw_misses,
		"max_combo_ever": raw_max_combo,
		"high_scores": high_scores,
		"best_accuracy": best_accuracy,
		"result_history": result_history,
		"song_unlocks": song_unlocks,
		"achievements": achievements,
		"daily": daily,
	}
	_dirty = false
	emit_signal("profile_loaded", _profile.duplicate())
	return _profile.duplicate()


func save_profile() -> bool:
	if not _dirty:
		return true
	var config := ConfigFile.new()

	config.set_value("profile", "level", _profile.get("level", 1))
	config.set_value("profile", "xp", _profile.get("xp", 0))
	config.set_value("profile", "xp_to_next", _profile.get("xp_to_next", 100))
	config.set_value("profile", "total_score", _profile.get("total_score", 0))
	config.set_value("profile", "plays", _profile.get("plays", 0))
	config.set_value("profile", "perfects", _profile.get("perfects", 0))
	config.set_value("profile", "goods", _profile.get("goods", 0))
	config.set_value("profile", "misses", _profile.get("misses", 0))
	config.set_value("profile", "max_combo_ever", _profile.get("max_combo_ever", 0))

	var scores_section: Dictionary = {}
	for key: Variant in _profile.get("high_scores", {}).keys():
		scores_section[str(key)] = int(_profile.get("high_scores", {}).get(key, 0))
	config.set_value("scores", "high_scores", scores_section)
	config.set_value("scores", "best_accuracy", _profile.get("best_accuracy", {}))
	config.set_value("history", "results", _profile.get("result_history", []))

	var unlocks_section: Dictionary = {}
	for key: Variant in _profile.get("song_unlocks", {}).keys():
		unlocks_section[str(key)] = bool(_profile.get("song_unlocks", {}).get(key, false))
	config.set_value("progression", "song_unlocks", unlocks_section)

	var ach_section: Dictionary = {}
	for key: Variant in _profile.get("achievements", {}).keys():
		var entry: Dictionary = _profile.get("achievements", {}).get(key, {})
		ach_section[str(key)] = {
			"unlocked": bool(entry.get("unlocked", false)),
			"progress": maxi(0, int(entry.get("progress", 0))),
		}
	config.set_value("achievements", "achievements", ach_section)

	config.set_value("daily", "last_reward_date", str(_profile.get("daily", {}).get("last_reward_date", "")))
	config.set_value("daily", "streak", maxi(0, int(_profile.get("daily", {}).get("streak", 0))))

	var err: Error = config.save(PROFILE_PATH)
	if err == OK:
		_dirty = false
		emit_signal("profile_saved")
		return true
	printerr("[PlayerProfile] Failed to save profile to ", PROFILE_PATH)
	return false


func get_profile() -> Dictionary:
	return _profile.duplicate()


func get_level() -> int:
	return int(_profile.get("level", 1))


func get_xp() -> int:
	return int(_profile.get("xp", 0))


func get_xp_to_next() -> int:
	return int(_profile.get("xp_to_next", 100))


func get_high_score(song_id: String) -> int:
	return maxi(0, int(_profile.get("high_scores", {}).get(song_id, 0)))


func is_song_unlocked(song_id: String) -> bool:
	return bool(_profile.get("song_unlocks", {}).get(song_id, false))


func get_song_unlocks() -> Dictionary:
	return _profile.get("song_unlocks", {}).duplicate()


func update_high_score(song_id: String, score: int) -> bool:
	if song_id == "":
		return false
	score = maxi(0, score)
	var current: int = get_high_score(song_id)
	if score <= current:
		return false
	_profile.get("high_scores", {})[song_id] = score
	_dirty = true
	emit_signal("high_score_updated", song_id, score)
	return true


func unlock_song(song_id: String) -> bool:
	if song_id == "":
		return false
	if is_song_unlocked(song_id):
		return false
	_profile.get("song_unlocks", {})[song_id] = true
	_dirty = true
	emit_signal("song_unlocked", song_id)
	return true


func record_play(result: Dictionary) -> void:
	"""Merge a completed play result into the profile."""
	var score: int = maxi(0, int(result.get("score", 0)))
	var combo: int = maxi(0, int(result.get("max_combo", 0)))
	var perfects: int = maxi(0, int(result.get("perfects", 0)))
	var goods: int = maxi(0, int(result.get("goods", 0)))
	var misses: int = maxi(0, int(result.get("misses", 0)))
	var song_id := String(result.get("song_id", ""))
	var accuracy := clampf(float(result.get("accuracy", 0.0)), 0.0, 100.0)

	_profile["plays"] = maxi(0, int(_profile.get("plays", 0))) + 1
	_profile["total_score"] = maxi(0, int(_profile.get("total_score", 0))) + score
	_profile["perfects"] = maxi(0, int(_profile.get("perfects", 0))) + perfects
	_profile["goods"] = maxi(0, int(_profile.get("goods", 0))) + goods
	_profile["misses"] = maxi(0, int(_profile.get("misses", 0))) + misses
	_profile["max_combo_ever"] = maxi(int(_profile.get("max_combo_ever", 0)), combo)
	if song_id != "":
		var high_scores: Dictionary = _profile.get("high_scores", {})
		if score > int(high_scores.get(song_id, 0)):
			high_scores[song_id] = score
			emit_signal("high_score_updated", song_id, score)
		var accuracy_records: Dictionary = _profile.get("best_accuracy", {})
		accuracy_records[song_id] = maxf(float(accuracy_records.get(song_id, 0.0)), accuracy)
	var history: Array = _profile.get("result_history", [])
	var saved_result := result.duplicate(true)
	saved_result["accuracy"] = accuracy
	history.append(saved_result)
	if history.size() > 100:
		history.pop_front()
	_profile["result_history"] = history

	_dirty = true


func add_xp(amount: int) -> void:
	amount = maxi(0, int(amount))
	if amount <= 0:
		return
	_profile["xp"] = maxi(0, int(_profile.get("xp", 0))) + amount
	var level: int = int(_profile.get("level", 1))
	var xp_to_next: int = int(_profile.get("xp_to_next", 100))
	while int(_profile.get("xp", 0)) >= xp_to_next:
		_profile["xp"] = int(_profile.get("xp", 0)) - xp_to_next
		level += 1
		xp_to_next = _xp_for_level(level)
		_profile["level"] = level
		_profile["xp_to_next"] = xp_to_next
		emit_signal("level_up", level)
	_dirty = true


func reset_profile() -> void:
	_profile = _default_profile()
	_dirty = true
	save_profile()


func flush() -> bool:
	return save_profile()


func _default_profile() -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"xp_to_next": 100,
		"total_score": 0,
		"plays": 0,
		"perfects": 0,
		"goods": 0,
		"misses": 0,
		"max_combo_ever": 0,
		"high_scores": {},
		"best_accuracy": {},
		"result_history": [],
		"song_unlocks": {},
		"achievements": {},
		"daily": {
			"last_reward_date": "",
			"streak": 0,
		},
	}


func _default_achievement_entry() -> Dictionary:
	return {
		"unlocked": false,
		"progress": 0,
	}


func _xp_for_level(level: int) -> int:
	return maxi(1, 100 + (level - 1) * 50)
