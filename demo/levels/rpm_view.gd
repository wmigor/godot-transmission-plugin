extends Control

var car: Car


func _process(_delta: float) -> void:
	if car != null:
		queue_redraw()


func _draw() -> void:
	if car == null:
		return
	var rect := get_rect()
	var radius := minf(rect.size.x, rect.size.y)
	var angle := lerpf(PI, TAU, car.transmission.motor.rpm / car.transmission.motor.torque_curve.max_rpm)
	var center := rect.size * 0.5
	var direction := Vector2(cos(angle), sin(angle))
	draw_line(center, center + direction * radius, Color.RED)
