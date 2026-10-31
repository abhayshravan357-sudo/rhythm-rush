# NoteSpawner.gd
# Node2D — garbage-collection-free object pool for visual note elements.
#
# All ColorRect nodes are pre-allocated at scene load. No new nodes are ever
# instantiated during gameplay, eliminating GC pauses on mobile hardware.
extends Node2D

const MAX_POOL_LIMIT: int = 200

var preallocated_node_pool: Array[ColorRect] = []
var active_rendering_array: Array[ColorRect] = []

@onready var lane_manager: Node2D = $"../LaneManager"

var next_evaluative_note_index: int = 0
var tracking_chart_timeline: Array = []


func _ready() -> void:
	preallocate_memory_pool()


func preallocate_memory_pool() -> void:
	for i: int in range(MAX_POOL_LIMIT):
		var tile := ColorRect.new()
		tile.set_process(false)
		tile.set_physics_process(false)
		tile.visible = false
		tile.size = Vector2(10.0, 10.0)  # Fallback bounds before lane layout resolves

		tile.set_meta("is_active", false)
		tile.set_meta("timeline_index", -1)
		tile.set_meta("lane_index", -1)
		tile.set_meta("note_type", "TAP")
		tile.set_meta("hold_duration", 0.0)

		add_child(tile)
		preallocated_node_pool.append(tile)


func start_spawning_sequence(chart_data: Dictionary) -> void:
	tracking_chart_timeline = chart_data["noteTimeline"]
	next_evaluative_note_index = 0
	active_rendering_array.clear()
	# Hide any tiles that were active from a previous game
	for tile: ColorRect in preallocated_node_pool:
		tile.visible = false
		tile.set_meta("is_active", false)


func _process(_delta: float) -> void:
	if not AudioSync.active_playback_flag:
		return

	var playback_time: float = AudioSync.adjusted_system_time

	# Spawn notes that are now within the visible approach window
	while next_evaluative_note_index < tracking_chart_timeline.size():
		var note_data: Dictionary = tracking_chart_timeline[next_evaluative_note_index]
		if note_data["timestamp"] - AudioSync.APPROACH_TIME <= playback_time:
			_deploy_pool_element(note_data, next_evaluative_note_index)
			next_evaluative_note_index += 1
		else:
			break  # Timeline is sorted; no later note can qualify yet

	_synchronize_active_elements(playback_time)


func _deploy_pool_element(note_spec: Dictionary, timeline_index: int) -> void:
	for tile: ColorRect in preallocated_node_pool:
		if tile.get_meta("is_active"):
			continue

		tile.set_meta("is_active", true)
		tile.set_meta("timeline_index", timeline_index)
		tile.set_meta("lane_index", note_spec["lane"])
		tile.set_meta("note_type", note_spec["type"])
		tile.set_meta("hold_duration", note_spec.get("duration", 0.0))

		_configure_tile_visual(tile, note_spec)
		tile.visible = true
		active_rendering_array.append(tile)
		return

	push_warning("[NoteSpawner] Pool exhausted — increase MAX_POOL_LIMIT.")


func _configure_tile_visual(tile: ColorRect, note_spec: Dictionary) -> void:
	var lane_idx: int = note_spec["lane"]
	var lane_w: float = lane_manager.get_lane_width()
	var tile_w: float = lane_w * 0.82
	var tile_h: float = 24.0

	if note_spec["type"] == "HOLD":
		var drop_dist: float = lane_manager.get_total_drop_distance()
		var hold_h: float = (note_spec.get("duration", 0.3) / AudioSync.APPROACH_TIME) * drop_dist
		tile_h = maxf(tile_h, hold_h)
		tile.color = Color("#29b6f6")  # Cyan — sustained note
	else:
		tile.color = Color("#e91e63")  # Pink — instant tap

	tile.size = Vector2(tile_w, tile_h)
	tile.position.x = lane_manager.get_lane_left_edge(lane_idx) + (lane_w * 0.09)


func _synchronize_active_elements(playback_time: float) -> void:
	var drop_dist: float = lane_manager.get_total_drop_distance()
	var judgment_y: float = lane_manager.get_judgment_line_y()

	var idx: int = active_rendering_array.size() - 1
	while idx >= 0:
		var tile: ColorRect = active_rendering_array[idx]
		var tl_idx: int = tile.get_meta("timeline_index")
		var note: Dictionary = tracking_chart_timeline[tl_idx]

		var hit_time: float = note["timestamp"]
		# Y = (audio_time - hit_time + approach) / approach * drop_distance
		var position_ratio: float = (
			(playback_time - hit_time + AudioSync.APPROACH_TIME) / AudioSync.APPROACH_TIME
		)
		var calc_y: float = position_ratio * drop_dist

		if tile.get_meta("note_type") == "HOLD":
			tile.position.y = calc_y - tile.size.y  # Bottom-anchored for HOLD notes
		else:
			tile.position.y = calc_y

		# Retire notes that have scrolled well past the judgment line
		if tile.position.y > (judgment_y + 60.0):
			_retire_tile(tile, idx)

		idx -= 1


func _retire_tile(tile: ColorRect, active_idx: int) -> void:
	tile.visible = false
	tile.set_meta("is_active", false)
	active_rendering_array.remove_at(active_idx)
