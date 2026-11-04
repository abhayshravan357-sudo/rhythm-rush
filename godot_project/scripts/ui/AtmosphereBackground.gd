extends ColorRect
## Lightweight original ambient glow, drawn once and refreshed only on resize.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var bounds := size
	if bounds.x <= 0.0 or bounds.y <= 0.0:
		return
	_draw_soft_glow(Vector2(bounds.x * 0.78, bounds.y * 0.25), bounds.x * 0.24, Color(0.05, 0.58, 0.78))
	_draw_soft_glow(Vector2(bounds.x * 0.12, bounds.y * 0.84), bounds.x * 0.2, Color(0.52, 0.16, 0.52))
	var orbit_center := Vector2(bounds.x * 0.79, bounds.y * 0.25)
	draw_arc(orbit_center, bounds.x * 0.19, 0.22, 2.18, 72, Color(0.3, 0.77, 0.91, 0.14), 1.5, true)
	draw_arc(orbit_center, bounds.x * 0.22, 3.45, 5.32, 72, Color(0.75, 0.34, 0.78, 0.12), 1.5, true)


func _draw_soft_glow(center: Vector2, radius: float, tint: Color) -> void:
	for layer in range(24):
		var ratio := 1.0 - float(layer) / 24.0
		var alpha := 0.002 + (1.0 - ratio) * 0.006
		draw_circle(center, radius * ratio, Color(tint.r, tint.g, tint.b, alpha))
