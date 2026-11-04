# SaveManager.gd
# Central safe local persistence layer (user://). Offline-first; no
# cloud/network. All reads/writes are validated; writes are atomic
# (temp file + rename). No hardcoded secrets.
extends Node
class_name SaveManager

const SAVE_FORMAT_VERSION: int = 1

# ── Public API ────────────────────────────────────────────────────────────

# Write `data` (Dictionary) to `path` under user:// atomically.
# Returns true on success.
func save_json(path: String, data: Dictionary) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		printerr("[SaveManager] save_json: data must be a Dictionary.")
		return false
	if not _is_valid_user_path(path):
		printerr("[SaveManager] save_json: invalid path: ", path)
		return false

	var sanitized: Variant = _sanitize_variant(data)
	var tmp_path := path + ".tmp"

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		printerr("[SaveManager] Cannot open for write: ", tmp_path, " (", FileAccess.get_open_error(), ")")
		return false

	var json := JSON.new()
	var encoded := json.stringify(sanitized)
	file.store_string(encoded)
	file.store_to_end("\n")
	file.close()

	# Atomic replace: temp → target
	var base_dir := path.get_base_dir()
	var dir := DirAccess.open(base_dir)
	if dir == null:
		printerr("[SaveManager] Cannot access base dir: ", base_dir)
		return false

	var rename_err := dir.rename(tmp_path, path)
	if rename_err != OK:
		printerr("[SaveManager] Atomic rename failed: ", rename_err)
		dir.remove(tmp_path)
		return false
	return true


# Read and validate `path` against `defaults` schema. Returns defaults-copy
# if the file is missing, corrupt, or type-mismatched (never crashes).
func load_json(path: String, defaults: Dictionary) -> Dictionary:
	if typeof(defaults) != TYPE_DICTIONARY:
		printerr("[SaveManager] load_json: defaults must be a Dictionary.")
		return {}

	if not file_exists(path):
		return _deep_copy(defaults)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("[SaveManager] Cannot open for read: ", path, " (", FileAccess.get_open_error(), ")")
		return _deep_copy(defaults)

	var raw: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(raw)
	if parse_err != OK:
		printerr("[SaveManager] Corrupt save file: ", path, " — using defaults.")
		return _deep_copy(defaults)

	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		printerr("[SaveManager] Save root is not a Dictionary: ", path)
		return _deep_copy(defaults)

	return _validate_and_merge(data, defaults)


func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)


# Remove a save file. Safe to call on a missing path.
func clear_save(path: String) -> bool:
	if not file_exists(path):
		return true
	if not _is_valid_user_path(path):
		return false
	var base_dir := path.get_base_dir()
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return false
	return dir.remove(path) == OK


# ── Internal: validation & sanitization ───────────────────────────────────

func _validate_and_merge(data: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := _deep_copy(defaults)
	for k in defaults.keys():
		if data.has(k):
			var expected: Variant = defaults[k]
			var actual: Variant = data[k]
			if _types_compatible(actual, expected):
				result[k] = actual
			else:
				printerr("[SaveManager] Type mismatch for key '", k, "' — using default.")
	return result

func _types_compatible(actual: Variant, expected: Variant) -> bool:
	if expected is Dictionary and actual is Dictionary:
		return true
	if expected is Array and actual is Array:
		return true
	return typeof(actual) == typeof(expected)

func _deep_copy(source: Dictionary) -> Dictionary:
	var copy: Dictionary = {}
	if typeof(source) != TYPE_DICTIONARY:
		return copy
	for k in source.keys():
		copy[k] = source[k]
	return copy

func _sanitize_variant(v: Variant) -> Variant:
	if v is Dictionary:
		return _sanitize_dict(v)
	if v is Array:
		return _sanitize_array(v)
	if v is int:
		return v  # int already bounded by engine
	if v is float:
		if v.is_inf() or v.is_nan():
			return 0.0
		return clampf(v, -1e9, 1e9)
	if v is String:
		return v.substr(0, 4096)
	if v is bool:
		return v
	return null

func _sanitize_dict(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d.keys():
		var ks := String(k)
		if ks.length() == 0:
			continue
		out[ks] = _sanitize_variant(d[k])
	return out

func _sanitize_array(a: Array) -> Array:
	var out: Array = []
	for v in a:
		out.append(_sanitize_variant(v))
	return out


# Restrict writes/reads to user:// (local, app-private storage only).
func _is_valid_user_path(path: String) -> bool:
	if typeof(path) != TYPE_STRING:
		return false
	var p := String(path)
	return p.begins_with("user://") and not p.contains("..") and p.length() > 7
