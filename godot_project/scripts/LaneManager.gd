# LaneManager.gd
# Node2D — viewport partitioning and multi-touch lane resolution.
#
# MVP uses 4 lanes; the column math is lane_count-driven so the foundation
# retains headroom for 6 lanes without code changes.
extends Node2D

signal column_touch_down(lane_index: int)
signal column_touch_up(lane_index: int)

# MVP lane count. Configurable; foundation supports up to 6.
@export var lane_count: int = 4

var screen_width: float = 1920.0
var screen_height: float = 1080.0
var column_width_step: float = 320.0   # screen_width / lane_count
var fixed_judgment_y: float = 918.0    # 85 % of 1080

# Gated by the gameplay state machine (countdown/playing/pause/results).
# Owned by Agent 01; LaneManager only exposes the control point.
var input_enabled: bool = false


func _ready() -> void:
	_evaluate_viewport_metrics()
	get_tree().root.size_changed.connect(_evaluate_viewport_metrics)
	# Route every registered touch to hit registration (ScoreManager).
	# ScoreManager is an Agent 05-owned autoload; we call it, never modify it.
	column_touch_down.connect(Callable(ScoreManager, "process_action_input"))


func _evaluate_viewport_metrics() -> void:
	var vp := get_viewport_rect().size
	screen_width = vp.x
	screen_height = vp.y
	# Divide screen into lane_count equal lane columns (viewport-relative).
	column_width_step = screen_width / float(lane_count)
	# Judgment line sits at 85 % of screen height.
	fixed_judgment_y = screen_height * 0.85


# ── Public API used by NoteSpawner and ScoreManager ───────────────────────────

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func is_input_enabled() -> bool:
	return input_enabled


func get_lane_count() -> int:
	return lane_count


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
	if not input_enabled:
		return
	if event is InputEventScreenTouch:
		var lane: int = int(event.position.x / column_width_step)
		lane = clampi(lane, 0, lane_count - 1)
		if event.pressed:
			emit_signal("column_touch_down", lane)
		else:
			emit_signal("column_touch_up", lane)
