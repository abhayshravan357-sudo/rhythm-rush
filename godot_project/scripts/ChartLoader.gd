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

	# Enforce chronological order as a safety guarantee for the spawning loop
	var timeline: Array = verified_dict["noteTimeline"]
	timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["timestamp"] < b["timestamp"]
	)

	current_chart = verified_dict
	is_chart_loaded = true
	print("[ChartLoader] Loaded ", timeline.size(), " notes from: ", file_path)
	return current_chart


func get_notes_in_window(time_start: float, time_end: float) -> Array:
	"""Returns all notes whose timestamps fall within [time_start, time_end]."""
	var notes_slice: Array = []
	if not is_chart_loaded:
		return notes_slice

	var timeline: Array = current_chart["noteTimeline"]
	for item: Dictionary in timeline:
		var note_time: float = item["timestamp"]
		if note_time >= time_start and note_time <= time_end:
			notes_slice.append(item)
	return notes_slice


func get_metadata() -> Dictionary:
	if is_chart_loaded:
		return current_chart.get("metaData", {})
	return {}
