extends Control
class_name WheelDeformationView

var wheel: Wheel:
	set(value):
		wheel = value
		queue_redraw()


func _process(_delta: float) -> void:
	if wheel != null or not wheel.use_relaxation:
		queue_redraw()


func _draw() -> void:
	if wheel == null or not wheel.use_relaxation:
		return

	var rect := get_rect()
	rect.position = Vector2.ZERO
	draw_rect(rect, Color.BLACK, false)
	var x := 0.5 * (rect.size.x + rect.size.x * wheel.deflection.y / wheel.relaxation_length)
	var y := 0.5 * (rect.size.y + rect.size.y * wheel.deflection.x / wheel.relaxation_length)
	draw_line(Vector2(x, 0.0), Vector2(x, rect.size.y), Color.RED)
	draw_line(Vector2(0.0, y), Vector2(rect.size.x, y), Color.RED)
