# LaneManager.gd
# Node2D — viewport partitioning and multi-touch lane resolution.
#
# MVP uses 4 lanes; the column math is lane_count-driven so the foundation
# retains headroom for 6 lanes without code changes.
extends Node2D

signal column_touch_down(lane_index: int)
signal column_touch_up(lane_index: int)

# MVP lane count. Configurable; foundation supports up to 6.
var lane_count: int = GameConfig.DEFAULT_LANE_COUNT

var screen_width: float = 1920.0
var screen_height: float = 1080.0
var column_width_step: float = 480.0   # default 1920 / 4
var fixed_judgment_y: float = 918.0   # 85 % of 1080

# Gated by the gameplay state machine (countdown/playing/pause/results).
# Owned by Agent 01; LaneManager only exposes the control point.
var input_enabled: bool = false

# Duplicate-input prevention: minimum time between accepted taps on the same lane.
const INPUT_COOLDOWN_SECONDS: float = 0.05  # 50 ms

# Active touches per lane (lane_index -> touch finger id) for simultaneous-input
# handling. A lane that already has a touch down ignores further presses until
# that finger is released.
var _active_touches: Dictionary = {}
# Last accepted tap time per lane (lane_index -> wall-clock seconds) for
# cooldown enforcement.
var _last_tap_time: Dictionary = {}


func _ready() -> void:
	lane_count = GameConfig.normalize_lane_count(lane_count)
	_evaluate_viewport_metrics()
	get_tree().root.size_changed.connect(_evaluate_viewport_metrics)
	# Route touch input through the local handler so it is gated by the gameplay
	# state machine before reaching ScoreManager (Agent 05-owned; we call it,
	# never modify it).
	column_touch_down.connect(Callable(self, "_on_column_touch_down"))
	column_touch_up.connect(Callable(self, "_on_column_touch_up")


func _evaluate_viewport_metrics() -> void:
	var vp := get_viewport_rect().size
	screen_width = vp.x
	screen_height = vp.y
	lane_count = GameConfig.normalize_lane_count(lane_count)
	column_width_step = screen_width / float(lane_count)
	# Judgment line sits at 85 % of screen height.
	fixed_judgment_y = screen_height * 0.85


# ── Public API used by NoteSpawner and ScoreManager ───────────────────────────

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func is_input_enabled() -> bool:
	return input_enabled


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
	if not input_enabled:
		return
	if event is InputEventScreenTouch:
		var lane: int = get_lane_index_for_x(event.position.x)
		if lane < 0:
			return
		if event.pressed:
			# Simultaneous-input handling: ignore presses on a lane that already
			# has an active touch. Different lanes are tracked independently.
			if _active_touches.has(lane):
				return
			# Duplicate-input prevention: ignore taps faster than the cooldown.
			var now: float = Time.get_ticks_msec() / 1000.0
			var last_tap: float = _last_tap_time.get(lane, -999.0)
			if now - last_tap < INPUT_COOLDOWN_SECONDS:
				return
			_active_touches[lane] = event.touch_index
			_last_tap_time[lane] = now
			emit_signal("column_touch_down", lane)
		else:
			# Touch up: release this lane's active touch if it matches the
			# finger that went down. Touch up is emitted regardless so HOLD
			# release handling can observe it downstream.
			var stored_id: Variant = _active_touches.get(lane, null)
			if stored_id != null and stored_id == event.touch_index:
				_active_touches.erase(lane)
			emit_signal("column_touch_up", lane)


func _on_column_touch_down(lane_index: int) -> void:
	if not GameStateManager.is_playing():
		return
	ScoreManager.process_action_input(lane_index)


func _on_column_touch_up(lane_index: int) -> void:
	# Reserved for HOLD-note release judgment (ScoreManager-owned, future MVP).
	# For MVP, touch-up only releases the lane's active-touch tracking above.
	pass
