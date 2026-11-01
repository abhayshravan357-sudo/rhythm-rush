# ChartLoader.gd
# Autoload Singleton — JSON chart IO, validation, and window slicing.
extends Node

var current_chart: Dictionary = {}
var is_chart_loaded: bool = false


func load_chart(file_path: String) -> Dictionary:
	is_chart_loaded = false
	current_chart.clear()

	if not FileAccess.file_exists(file_path):
		printerr("[ChartLoader] Missing resource: ", file_path)
		return {}

	var file_handle := FileAccess.open(file_path, FileAccess.READ)
	if file_handle == null:
		printerr("[ChartLoader] IO open error: ", FileAccess.get_open_error())
		return {}

	var raw_text := file_handle.get_as_text()
	file_handle.close()

	var json_parser := JSON.new()
	var error_status := json_parser.parse(raw_text)
	if error_status != OK:
		printerr(
			"[ChartLoader] JSON parse failure at line ",
			json_parser.get_error_line(),
			": ",
			json_parser.get_error_message()
		)
		return {}

	var parsed_data: Variant = json_parser.get_data()
	if typeof(parsed_data) != TYPE_DICTIONARY:
		printerr("[ChartLoader] Root must be a Dictionary.")
		return {}

	var verified_dict: Dictionary = parsed_data
	if not (verified_dict.has("metaData") and verified_dict.has("noteTimeline")):
		printerr("[ChartLoader] Missing required root keys: metaData or noteTimeline.")
		return {}

	var normalized_chart: Dictionary = validate_chart_payload(verified_dict)
	if normalized_chart.is_empty():
		printerr("[ChartLoader] Chart failed validation and was rejected.")
		return {}

	current_chart = normalized_chart
	is_chart_loaded = true
	print("[ChartLoader] Loaded ", current_chart["noteTimeline"].size(), " notes from: ", file_path)
	return current_chart


func validate_chart_payload(chart_payload: Dictionary) -> Dictionary:
	if typeof(chart_payload) != TYPE_DICTIONARY or chart_payload.is_empty():
		return {}

	var upstream_meta: Dictionary = chart_payload.get("metaData", {})
	if typeof(upstream_meta) != TYPE_DICTIONARY:
		return {}

	var lane_count: int = int(upstream_meta.get("laneCount", GameConfig.DEFAULT_LANE_COUNT))
	lane_count = GameConfig.normalize_lane_count(lane_count)
	var timeline: Array = chart_payload.get("noteTimeline", [])
	if typeof(timeline) != TYPE_ARRAY:
		return {}

	var normalized_timeline: Array = []
	for i: Variant in timeline:
		if typeof(i) != TYPE_DICTIONARY:
			continue
		var note: Dictionary = i
		var timestamp: float = float(note.get("timestamp", -1.0))
		var lane: int = int(note.get("lane", -1))
		var note_type: String = String(note.get("type", "TAP")).to_upper()
		if not is_finite(timestamp) or timestamp < 0.0:
			continue
		if lane < 0 or lane >= lane_count:
			continue
		if not (note_type == "TAP" or note_type == "HOLD" or note_type == "SIMULTANEOUS"):
			continue
		if note_type == "HOLD":
			var duration: float = float(note.get("duration", 0.0))
			if duration <= 0.0:
				continue
		var normalized_note: Dictionary = {
			"timestamp": timestamp,
			"lane": lane,
			"type": note_type,
			"source": note.get("source", "auto")
		}
		if note_type == "HOLD":
			normalized_note["duration"] = float(note.get("duration", 0.0))
		normalized_timeline.append(normalized_note)

	normalized_timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["timestamp"] < b["timestamp"]
	)

	if normalized_timeline.is_empty():
		return {}

	var sanitized_chart: Dictionary = chart_payload.duplicate(true)
	sanitized_chart["metaData"] = upstream_meta.duplicate(true)
	sanitized_chart["metaData"]["laneCount"] = lane_count
	sanitized_chart["noteTimeline"] = normalized_timeline
	return sanitized_chart


func get_notes_in_window(time_start: float, time_end: float) -> Array:
	"""Returns all notes whose timestamps fall within [time_start, time_end]."""
	var notes_slice: Array = []
	if not is_chart_loaded:
		return notes_slice

	var timeline: Array = current_chart.get("noteTimeline", [])
	for item: Dictionary in timeline:
		var note_time: float = float(item.get("timestamp", -1.0))
		if note_time >= time_start and note_time <= time_end:
			notes_slice.append(item)
	return notes_slice


func get_metadata() -> Dictionary:
	if is_chart_loaded:
		return current_chart.get("metaData", {})
	return {}
