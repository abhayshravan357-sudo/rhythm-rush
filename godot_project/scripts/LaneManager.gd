# LaneManager.gd
# Node2D — viewport partitioning and multi-touch lane resolution.
extends Node2D

signal column_touch_down(lane_index: int)
signal column_touch_up(lane_index: int)

var screen_width: float = 1920.0
var screen_height: float = 1080.0
var column_width_step: float = 320.0   # 1920 / 6
var fixed_judgment_y: float = 918.0   # 85 % of 1080


func _ready() -> void:
	_evaluate_viewport_metrics()
	get_tree().root.size_changed.connect(_evaluate_viewport_metrics)


func _evaluate_viewport_metrics() -> void:
	var vp := get_viewport_rect().size
	screen_width = vp.x
	screen_height = vp.y
	# Divide screen into 6 equal lane columns
	column_width_step = screen_width / 6.0
	# Judgment line sits at 85 % of screen height
	fixed_judgment_y = screen_height * 0.85


# ── Public API used by NoteSpawner and ScoreManager ───────────────────────────

func get_lane_width() -> float:
	return column_width_step


func get_lane_left_edge(lane_index: int) -> float:
	return float(lane_index) * column_width_step


func get_judgment_line_y() -> float:
	return fixed_judgment_y


func get_total_drop_distance() -> float:
	## Notes spawn at y=0 (top of viewport) and fall to the judgment line.
	return fixed_judgment_y


# ── Input handling ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var lane: int = int(event.position.x / column_width_step)
		lane = clampi(lane, 0, 5)
		if event.pressed:
			emit_signal("column_touch_down", lane)
		else:
			emit_signal("column_touch_up", lane)
