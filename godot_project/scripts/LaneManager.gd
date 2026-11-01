# LaneManager.gd
# Node2D — viewport partitioning and multi-touch lane resolution.
extends Node2D

signal column_touch_down(lane_index: int)
signal column_touch_up(lane_index: int)

var screen_width: float = 1920.0
var screen_height: float = 1080.0
var lane_count: int = GameConfig.DEFAULT_LANE_COUNT
var column_width_step: float = 480.0   # default 1920 / 4
var fixed_judgment_y: float = 918.0   # 85 % of 1080


func _ready() -> void:
	lane_count = GameConfig.normalize_lane_count(lane_count)
	_evaluate_viewport_metrics()
	get_tree().root.size_changed.connect(_evaluate_viewport_metrics)
	column_touch_down.connect(_on_column_touch_down)


func _evaluate_viewport_metrics() -> void:
	var vp := get_viewport_rect().size
	screen_width = vp.x
	screen_height = vp.y
	lane_count = GameConfig.normalize_lane_count(lane_count)
	column_width_step = screen_width / float(lane_count)
	fixed_judgment_y = screen_height * 0.85


# ── Public API used by NoteSpawner and ScoreManager ───────────────────────────

func get_lane_count() -> int:
	return GameConfig.normalize_lane_count(lane_count)


func get_lane_width() -> float:
	return column_width_step


func get_lane_left_edge(lane_index: int) -> float:
	var target_lane: int = clampi(lane_index, 0, get_lane_count() - 1)
	return float(target_lane) * column_width_step


func get_lane_index_for_x(screen_x: float) -> int:
	if screen_x < 0.0:
		return -1
	var normalized_lane: int = int(screen_x / column_width_step)
	normalized_lane = clampi(normalized_lane, 0, get_lane_count() - 1)
	return normalized_lane


func get_judgment_line_y() -> float:
	return fixed_judgment_y


func get_total_drop_distance() -> float:
	## Notes spawn at y=0 (top of viewport) and fall to the judgment line.
	return fixed_judgment_y


# ── Input handling ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var lane: int = get_lane_index_for_x(event.position.x)
		if lane < 0:
			return
		if event.pressed:
			emit_signal("column_touch_down", lane)
		else:
			emit_signal("column_touch_up", lane)


func _on_column_touch_down(lane_index: int) -> void:
	if not GameStateManager.is_playing():
		return
	ScoreManager.process_action_input(lane_index)
