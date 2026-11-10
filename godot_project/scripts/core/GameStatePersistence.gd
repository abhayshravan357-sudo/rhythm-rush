# GameStatePersistence.gd
# Autoload Singleton — game state persistence with integrity verification.
#
# Saves and loads arbitrary game state dictionaries to user:// using JSON format
# with an embedded checksum so callers can detect corruption or tampering on load.
#
# Signals:
#   state_saved(path) — emitted after a successful save
#   state_load_failed(reason) — emitted when load or validation fails
#
# The persisted file layout:
#   {
#     "data": <the caller-supplied dictionary>,
#     "checksum": <hex string of the data checksum>,
#     "version": 1,
#     "saved_at": <unix timestamp seconds>
#   }
extends Node

const SAVE_PATH := "user://game_state.json"
const SAVE_VERSION := 1

var last_save_error: String = ""


signal state_saved(path: String)
signal state_load_failed(reason: String)


# ── Checksum ──────────────────────────────────────────────────────────────────

func _compute_checksum(json_string: String) -> String:
	"""Simple additive checksum over the JSON bytes (hex string)."""
	var sum: int = 0
	for i in range(json_string.length()):
		sum = (sum + int(String(json_string[i]).to_utf8_buffer()[0] if json_string[i].length() > 0 else 0)) % 65536
	return "%04x" % sum


# ── Public API ────────────────────────────────────────────────────────────────

func save_game_state(data_dict: Dictionary) -> bool:
	"""Persist data_dict to user:// with a checksum. Returns true on success."""
	last_save_error = ""

	var payload: Dictionary = {
		"data": data_dict.duplicate(true),
		"checksum": "",
		"version": SAVE_VERSION,
		"saved_at": int(Time.get_unix_time_from_system())
	}

	var json_string: String = JSON.stringify(payload)
	var checksum: String = _compute_checksum(json_string)
	payload["checksum"] = checksum

	json_string = JSON.stringify(payload)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_save_error = "Could not open " + SAVE_PATH + " for writing"
		printerr("[GameStatePersistence] ", last_save_error)
		emit_signal("state_load_failed", last_save_error)
		return false

	file.store_string(json_string)
	file.close()

	emit_signal("state_saved", SAVE_PATH)
	return true


func load_game_state() -> Dictionary:
	"""Load and validate persisted game state. Returns {} on failure."""
	last_save_error = ""

	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_save_error = "Could not open " + SAVE_PATH + " for reading"
		printerr("[GameStatePersistence] ", last_save_error)
		emit_signal("state_load_failed", last_save_error)
		return {}

	var json_string: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(json_string)
	if parse_error != OK:
		last_save_error = "Invalid JSON in " + SAVE_PATH
		printerr("[GameStatePersistence] ", last_save_error)
		emit_signal("state_load_failed", last_save_error)
		return {}

	var payload: Variant = json.get_data()
	if typeof(payload) != TYPE_DICTIONARY:
		last_save_error = "Persisted payload is not a Dictionary"
		printerr("[GameStatePersistence] ", last_save_error)
		emit_signal("state_load_failed", last_save_error)
		return {}

	if not validate_save_data(payload):
		last_save_error = "Save data failed integrity validation"
		printerr("[GameStatePersistence] ", last_save_error)
		emit_signal("state_load_failed", last_save_error)
		return {}

	var data: Dictionary = payload.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data.duplicate(true)


func validate_save_data(payload: Dictionary) -> bool:
	"""Validate structure, version, and checksum of a persisted payload."""
	if typeof(payload) != TYPE_DICTIONARY:
		return false

	if payload.get("version", -1) != SAVE_VERSION:
		return false

	var stored_checksum: String = String(payload.get("checksum", ""))
	if stored_checksum.is_empty():
		return false

	var payload_copy: Dictionary = payload.duplicate(true)
	payload_copy["checksum"] = ""

	var json_string: String = JSON.stringify(payload_copy)
	var computed_checksum: String = _compute_checksum(json_string)

	return computed_checksum == stored_checksum


func clear_save_data() -> bool:
	"""Delete the persisted save file. Returns true on success (or if file absent)."""
	if not FileAccess.file_exists(SAVE_PATH):
		return true

	var err := FileAccess.remove(SAVE_PATH)
	if err != OK:
		last_save_error = "Could not remove " + SAVE_PATH
		printerr("[GameStatePersistence] ", last_save_error)
		emit_signal("state_load_failed", last_save_error)
		return false

	return true
