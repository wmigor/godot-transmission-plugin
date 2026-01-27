extends Control

var _transmission: Transmission


func _ready() -> void:
	_transmission = get_node("../../KiaRio/Transmission")


func _process(_delta: float) -> void:
	if _transmission != null:
		queue_redraw()


func _draw() -> void:
	if _transmission == null:
		return
	var rect := get_rect()
	var radius := minf(rect.size.x, rect.size.y)
	var angle := lerpf(PI, TAU, _transmission.motor.rpm / _transmission.motor.torque_curve.max_rpm)
	var center := rect.size * 0.5
	var direction := Vector2(cos(angle), sin(angle))
	draw_line(center, center + direction * radius, Color.RED)
