extends RefCounted
## Shared viewport-aware sizing for centered application panels.


static func fit_centered_box(control: Control, max_width: float, max_height: float, safe_margin: float = 24.0) -> void:
	var viewport_size := control.get_viewport_rect().size
	var box_rect := centered_box_rect(viewport_size, Vector2(max_width, max_height), safe_margin)
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = box_rect.position.x - viewport_size.x * 0.5
	control.offset_right = box_rect.end.x - viewport_size.x * 0.5
	control.offset_top = box_rect.position.y - viewport_size.y * 0.5
	control.offset_bottom = box_rect.end.y - viewport_size.y * 0.5


static func centered_box_rect(viewport_size: Vector2, max_size: Vector2, safe_margin: float = 24.0) -> Rect2:
	var box_size := Vector2(
		maxf(0.0, minf(max_size.x, viewport_size.x - safe_margin * 2.0)),
		maxf(0.0, minf(max_size.y, viewport_size.y - safe_margin * 2.0))
	)
	return Rect2((viewport_size - box_size) * 0.5, box_size)
