# LaneManager.gd
# Node2D — viewport partitioning and multi-touch lane resolution.
#
# MVP uses 4 lanes; the column math is lane_count-driven so the foundation
# retains headroom for 6 lanes without code changes.
#
# MVP-03 input refinement:
#   - Duplicate input processing prevention: per-lane tap debounce suppresses
#     rapid-fire repeat taps on the same lane within DEBOUNCE_SECONDS.
#   - Simultaneous input: each InputEvent is handled independently, so
#     multi-touch on different lanes resolves concurrently.
#   - Input gated by GameStateManager.is_playing(); disabled outside gameplay.
extends Node2D

const VisualTokens = preload("res://scripts/ui/VisualTokens.gd")

signal column_touch_down(lane_index: int)
signal column_touch_up(lane_index: int)

# MVP lane count. Configurable; foundation supports up to 6.
var lane_count: int = GameConfig.DEFAULT_LANE_COUNT

var screen_width: float = 1920.0
var screen_height: float = 1080.0
var column_width_step: float = 480.0   # default 1920 / 4
var fixed_judgment_y: float = 918.0   # 85 % of 1080
var playfield_left: float = 0.0
var playfield_top: float = 0.0
var playfield_width: float = 1920.0

# Gated by the gameplay state machine (countdown/playing/pause/results).
# Owned by Agent 01; LaneManager only exposes the control point.
var input_enabled: bool = false
var _lane_flash_until: Dictionary = {}

# MVP-03: per-lane tap debounce to suppress duplicate rapid input.
const DEBOUNCE_SECONDS: float = 0.08  # 80 ms minimum between same-lane taps
var _last_tap_time: Dictionary = {}   # lane_index (int) -> last tap time (float)

# MVP-04: touch deadzone radius in pixels. Taps within this distance of a
# lane boundary are rejected to prevent accidental adjacent-lane input.
const TOUCH_DEADZONE_RADIUS: float = 8.0
var touch_deadzone_radius: float = TOUCH_DEADZONE_RADIUS


func _ready() -> void:
	lane_count = GameConfig.normalize_lane_count(lane_count)
	_evaluate_viewport_metrics()
	get_viewport().size_changed.connect(_evaluate_viewport_metrics)
	queue_redraw()
	# Route every registered touch to hit registration (ScoreManager).
	# ScoreManager is an Agent 05-owned autoload; we call it, never modify it.
	column_touch_down.connect(Callable(ScoreManager, "process_action_input"))


func _evaluate_viewport_metrics() -> void:
	var vp := get_viewport_rect().size
	screen_width = vp.x
	screen_height = vp.y
	lane_count = GameConfig.normalize_lane_count(lane_count)
	column_width_step = screen_width / float(lane_count)
	# Keep a centered, bounded field at wide aspect ratios and preserve generous
	# lane width at portrait sizes. All gameplay visuals use the same geometry.
	var side_margin := clampf(screen_width * 0.075, 18.0, 120.0)
	playfield_width = maxf(1.0, screen_width - side_margin * 2.0)
	playfield_left = (screen_width - playfield_width) * 0.5
	playfield_top = clampf(screen_height * 0.14, 72.0, 154.0)
	fixed_judgment_y = screen_height * 0.84
	column_width_step = playfield_width / float(lane_count)
	queue_redraw()


func _draw() -> void:
	if playfield_width <= 0.0 or screen_height <= 0.0:
		return
	var field_bottom := fixed_judgment_y + maxf(24.0, screen_height * 0.055)
	var field_rect := Rect2(playfield_left, playfield_top, playfield_width, field_bottom - playfield_top)
	draw_rect(field_rect, VisualTokens.SURFACE, true)
	draw_rect(field_rect, VisualTokens.BORDER, false, 2.0)
	for lane in range(get_lane_count()):
		var x := playfield_left + float(lane) * column_width_step
		var lane_rect := Rect2(x + 3.0, playfield_top + 2.0, column_width_step - 6.0, field_rect.size.y - 4.0)
		var lane_color := Color("#132139") if lane % 2 == 0 else VisualTokens.SURFACE_ALT
		draw_rect(lane_rect, lane_color, true)
		draw_rect(Rect2(x, playfield_top, 1.5, field_rect.size.y), Color(0.36, 0.53, 0.76, 0.38), true)
		var center_x := x + column_width_step * 0.5
		var active := float(_lane_flash_until.get(lane, 0.0)) > Time.get_ticks_msec() / 1000.0
		var receptor := Rect2(x + column_width_step * 0.1, fixed_judgment_y - 13.0, column_width_step * 0.8, 26.0)
		draw_rect(receptor, Color(0.18, 0.76, 0.94, 0.48 if active else 0.16), true)
		draw_rect(receptor, Color(0.48, 0.91, 1.0, 0.92 if active else 0.48), false, 2.0)
		draw_circle(Vector2(center_x, fixed_judgment_y), minf(5.0, column_width_step * 0.04), Color.WHITE if active else VisualTokens.CYAN_SOFT)
	# Upper and lower rails make the field legible even before a note arrives.
	draw_rect(Rect2(playfield_left, playfield_top, playfield_width, 2.0), Color(0.38, 0.73, 1.0, 0.75), true)
	draw_rect(Rect2(playfield_left, field_bottom - 2.0, playfield_width, 2.0), Color(0.38, 0.73, 1.0, 0.65), true)

	# HOLD note lane zones: semi-transparent bars above each lane receptor
	# so players can see where sustained input is expected.
	for lane in range(get_lane_count()):
		var hold_rect := get_lane_hold_zone_rect(lane)
		if hold_rect.size.x > 0.0 and hold_rect.size.y > 0.0:
			draw_rect(hold_rect, Color(0.38, 0.73, 1.0, 0.08), true)
			draw_rect(hold_rect, Color(0.38, 0.73, 1.0, 0.35), false, 1.0)


func _process(_delta: float) -> void:
	if not _lane_flash_until.is_empty():
		var now := Time.get_ticks_msec() / 1000.0
		for lane in _lane_flash_until.keys():
			if float(_lane_flash_until[lane]) <= now:
				_lane_flash_until.erase(lane)
		queue_redraw()


func _flash_lane(lane_index: int) -> void:
	_lane_flash_until[lane_index] = Time.get_ticks_msec() / 1000.0 + 0.14
	queue_redraw()


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
	return playfield_left + float(target_lane) * column_width_step


func get_lane_index_for_x(screen_x: float) -> int:
	if screen_x < playfield_left or screen_x >= playfield_left + playfield_width:
		return -1
	var normalized_lane: int = int((screen_x - playfield_left) / column_width_step)
	normalized_lane = clampi(normalized_lane, 0, get_lane_count() - 1)
	return normalized_lane


func get_judgment_line_y() -> float:
	return fixed_judgment_y

func get_lane_hold_zone_rect(lane_index: int) -> Rect2:
	"""Return the hold note zone rectangle for a lane.

	The zone sits directly above the judgment line receptor and spans
	the lane width with a height proportional to a typical hold duration
	(1.0 second at the default approach time).
	"""
	var lane_idx: int = clampi(lane_index, 0, get_lane_count() - 1)
	var lane_x: float = playfield_left + float(lane_idx) * column_width_step
	var lane_w: float = column_width_step
	var hold_h: float = maxf(60.0, (1.0 / AudioSync.APPROACH_TIME) * get_total_drop_distance() * 0.4)
	return Rect2(lane_x + 2.0, fixed_judgment_y - hold_h, lane_w - 4.0, hold_h)

func set_touch_deadzone(radius_pixels: float) -> void:
	touch_deadzone_radius = max(0.0, float(radius_pixels))

func get_touch_deadzone_radius() -> float:
	return touch_deadzone_radius

func is_tap_in_deadzone(screen_x: float, lane_index: int) -> bool:
	"""Return true if a tap at screen_x is within the deadzone of lane_index boundaries.

	Deadzone is the region within touch_deadzone_radius pixels of either lane edge.
	Taps here are ambiguous and should be rejected to avoid accidental adjacent-lane
	input on mobile touchscreens.
	"""
	if touch_deadzone_radius <= 0.0:
		return false
	var lane_x: float = playfield_left + float(lane_index) * column_width_step
	var left_edge: float = lane_x + 2.0
	var right_edge: float = lane_x + column_width_step - 2.0
	if screen_x < left_edge + touch_deadzone_radius and screen_x > left_edge - touch_deadzone_radius:
		return true
	if screen_x < right_edge + touch_deadzone_radius and screen_x > right_edge - touch_deadzone_radius:
		return true
	return false


func get_total_drop_distance() -> float:
	## Notes travel through the visible playfield from its upper rail to receptors.
	return fixed_judgment_y - playfield_top


func get_playfield_top() -> float:
	return playfield_top


func get_playfield_left() -> float:
	return playfield_left


func get_playfield_width() -> float:
	return playfield_width


# ── Debounce (duplicate input prevention) ─────────────────────────────────────

func _is_tap_debounced(lane_index: int, now: float) -> bool:
	var last: float = _last_tap_time.get(lane_index, -999.0)
	if now - last < DEBOUNCE_SECONDS:
		return true
	return false


func _record_tap(lane_index: int, now: float) -> void:
	_last_tap_time[lane_index] = now


# ── Input handling ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var keyboard_lane := _keyboard_lane_for_key(event.keycode)
		if keyboard_lane >= 0:
			_flash_lane(keyboard_lane)
			emit_signal("column_touch_down", keyboard_lane)
		return
	if event is InputEventScreenTouch:
		var lane: int = get_lane_index_for_x(event.position.x)
		if lane < 0:
			return
		if event.pressed:
			_flash_lane(lane)
			emit_signal("column_touch_down", lane)
		else:
			emit_signal("column_touch_up", lane)
	elif event is InputEventMouseButton:
		var lane: int = get_lane_index_for_x(event.position.x)
		if lane < 0:
			return
		if event.pressed:
			_flash_lane(lane)
			emit_signal("column_touch_down", lane)
		else:
			emit_signal("column_touch_up", lane)


func _keyboard_lane_for_key(keycode: Key) -> int:
	var key_lanes: Array[Key] = [KEY_A, KEY_S, KEY_D, KEY_F]
	if get_lane_count() == 6:
		key_lanes = [KEY_A, KEY_S, KEY_D, KEY_J, KEY_K, KEY_L]
	return key_lanes.find(keycode)


func _on_column_touch_down(lane_index: int) -> void:
	if not GameStateManager.is_playing():
		return
	# MVP-03 duplicate prevention: debounce rapid same-lane taps so a single
	# physical tap cannot register as multiple judgments on the same note.
	var now: float = Time.get_ticks_msec() / 1000.0
	if _is_tap_debounced(lane_index, now):
		return
	_record_tap(lane_index, now)
	ScoreManager.process_action_input(lane_index)
