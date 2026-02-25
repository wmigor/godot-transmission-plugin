extends Control
class_name WheelDeformationView

var wheel: Wheel:
	set(value):
		wheel = value
		queue_redraw()


func _process(_delta: float) -> void:
	if wheel != null and wheel.use_relaxation:
		queue_redraw()


func _draw() -> void:
	if wheel == null or not wheel.use_relaxation:
		return

	var rect := get_rect()
	rect.position = Vector2.ZERO
	draw_rect(rect, Color.BLACK, false)
	var dx := (wheel.deflection.x / wheel.deflection_limit.x) if wheel.deflection_limit.x > 0.0 else 0.0
	var dy := (wheel.deflection.y / wheel.deflection_limit.y) if wheel.deflection_limit.y > 0.0 else 0.0
	var x := 0.5 * (rect.size.x + rect.size.x * dy)
	var y := 0.5 * (rect.size.y + rect.size.y * dx)
	draw_line(Vector2(x, 0.0), Vector2(x, rect.size.y), Color.RED)
	draw_line(Vector2(0.0, y), Vector2(rect.size.x, y), Color.RED)
