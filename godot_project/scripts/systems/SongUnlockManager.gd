# SongUnlockManager.gd
# Song unlocking structure: locked/unlocked states for song selection.
# Persisted to user://song_unlocks.dat via SaveManager. Integrity rules:
#   - songs never regress to locked once unlocked (unless default-unlocked)
#   - default-unlocked songs cannot be manually locked
# No hardcoded secrets.
extends Node

const SAVE_PATH: String = "user://song_unlocks.dat"

# Default catalogue: song_id -> {title, unlocked_by_default}
# Agent 04 / Agent 02 populate this from the song catalogue at startup.
var song_catalogue: Dictionary = {
	"tutorial": {"title": "Tutorial", "unlocked_by_default": true},
}

# song_id -> {unlocked: bool, unlocked_at: int, progress: float}
var song_states: Dictionary = {}

var _save_mgr: SaveManager = null


func _enter_tree() -> void:
	_ensure_save()


func _ensure_save() -> SaveManager:
	if _save_mgr == null:
		_save_mgr = SaveManager.new()
	return _save_mgr


# ── Lifecycle ─────────────────────────────────────────────────────────────

# Replace the catalogue and rebuild unlock states. Call once at startup with
# the full song catalogue (from Agent 04/UI or chart manifest).
func set_catalogue(catalogue: Dictionary) -> void:
	song_catalogue = catalogue if typeof(catalogue) == TYPE_DICTIONARY else {}
	if song_catalogue.size() == 0:
		song_catalogue = {"tutorial": {"title": "Tutorial", "unlocked_by_default": true}}
	_rebuild_states_from_catalogue()

func _rebuild_states_from_catalogue() -> void:
	song_states = {}
	for sid in song_catalogue.keys():
		var entry: Variant = song_catalogue[sid]
		var unlocked_by_default: bool = false
		if typeof(entry) == TYPE_DICTIONARY:
			unlocked_by_default = bool(entry.get("unlocked_by_default", false))
		song_states[sid] = {
			"unlocked": unlocked_by_default,
			"unlocked_at": 0 if unlocked_by_default else -1,
			"progress": 0.0,
		}

# Load persisted unlocks, merged over catalogue defaults. Never crashes on
# corrupt data; falls back to catalogue defaults.
func load() -> bool:
	var data: Dictionary = _ensure_save().load_json(SAVE_PATH, {"song_states": {}})
	var raw_states: Variant = data.get("song_states", {})
	if typeof(raw_states) != TYPE_DICTIONARY:
		raw_states = {}

	song_states = {}
	for sid in song_catalogue.keys():
		var persisted: Variant = raw_states.get(sid, {})
		if typeof(persisted) != TYPE_DICTIONARY:
			persisted = {}
		var entry: Variant = song_catalogue[sid]
		var default_unlocked: bool = false
		if typeof(entry) == TYPE_DICTIONARY:
			default_unlocked = bool(entry.get("unlocked_by_default", false))

		var unlocked: bool = default_unlocked
		if persisted.has("unlocked") and typeof(persisted["unlocked"]) == TYPE_BOOL:
			unlocked = persisted["unlocked"]
		# Integrity: a song never regresses to locked once unlocked.
		if unlocked and not default_unlocked:
			unlocked = true

		song_states[sid] = {
			"unlocked": unlocked,
			"unlocked_at": _as_int(persisted.get("unlocked_at", 0 if unlocked else -1)),
			"progress": clampf(_as_float(persisted.get("progress", 0.0)), 0.0, 1.0),
		}
	return true

func save() -> bool:
	var data: Dictionary = {"song_states": song_states}
	return _ensure_save().save_json(SAVE_PATH, data)


# ── Query API ─────────────────────────────────────────────────────────────

func is_unlocked(song_id: Variant) -> bool:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_states.has(sid):
		return false
	var state: Variant = song_states[sid]
	return bool(state.get("unlocked", false)) if typeof(state) == TYPE_DICTIONARY else false

func get_progress(song_id: Variant) -> float:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_states.has(sid):
		return 0.0
	var state: Variant = song_states[sid]
	if typeof(state) != TYPE_DICTIONARY:
		return 0.0
	return clampf(_as_float(state.get("progress", 0.0)), 0.0, 1.0)

func get_unlocked_at(song_id: Variant) -> int:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_states.has(sid):
		return -1
	var state: Variant = song_states[sid]
	return _as_int(state.get("unlocked_at", -1)) if typeof(state) == TYPE_DICTIONARY else -1

func get_all_states() -> Dictionary:
	var out: Dictionary = {}
	for sid in song_states.keys():
		out[String(sid)] = song_states[sid].duplicate()
	return out

func get_unlocked_songs() -> Array:
	var out: Array = []
	for sid in song_states.keys():
		if is_unlocked(sid):
			out.append(sid)
	return out

func get_catalogue() -> Dictionary:
	return song_catalogue.duplicate()

func get_title(song_id: Variant) -> String:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_catalogue.has(sid):
		return ""
	var entry: Variant = song_catalogue[sid]
	return String(entry.get("title", sid)) if typeof(entry) == TYPE_DICTIONARY else String(sid)


# ── Mutation API ──────────────────────────────────────────────────────────

# Unlock a song. Returns true if state changed.
func unlock_song(song_id: Variant) -> bool:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_catalogue.has(sid) or not song_states.has(sid):
		return false
	if bool(song_states[sid].get("unlocked", false)):
		return false  # already unlocked
	song_states[sid]["unlocked"] = true
	if _as_int(song_states[sid].get("unlocked_at", -1)) < 0:
		song_states[sid]["unlocked_at"] = _unix_now()
	return true

# Lock a song. Default-unlocked songs cannot be locked (integrity).
func lock_song(song_id: Variant) -> bool:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_catalogue.has(sid) or not song_states.has(sid):
		return false
	var entry: Variant = song_catalogue[sid]
	if typeof(entry) == TYPE_DICTIONARY and bool(entry.get("unlocked_by_default", false)):
		return false  # default-unlocked songs cannot be locked
	song_states[sid]["unlocked"] = false
	return true

func set_progress(song_id: Variant, progress: Variant) -> bool:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_states.has(sid):
		return false
	song_states[sid]["progress"] = clampf(_as_float(progress), 0.0, 1.0)
	return true

# Unlock a song when a score threshold is met. Returns true if the song was
# newly unlocked (or was already unlocked). Safe to call repeatedly.
func unlock_song_on_score(song_id: Variant, score: int, threshold: int) -> bool:
	var sid := _validate_song_id(song_id)
	if sid == "" or not song_catalogue.has(sid) or not song_states.has(sid):
		return false
	if score < threshold:
		return false  # threshold not met
	return unlock_song(sid)


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

func _unix_now() -> int:
	return int(Time.get_unix_time_from_system())

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
