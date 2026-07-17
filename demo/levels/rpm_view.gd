extends Control

var car: Car
var _angle: float


func _process(_delta: float) -> void:
	if car != null:
		set_rpm(car.transmission.motor.rpm, car.transmission.motor.torque_curve.max_rpm)


func _draw() -> void:
	var rect := get_rect()
	var radius := minf(rect.size.x, rect.size.y)
	var center := rect.size * 0.5
	var direction := Vector2(cos(_angle), sin(_angle))
	draw_line(center, center + direction * radius, Color.RED)


func set_rpm(rpm: float, max_rpm: float) -> void:
	_angle = lerpf(PI, TAU, rpm / max_rpm)
	queue_redraw()
