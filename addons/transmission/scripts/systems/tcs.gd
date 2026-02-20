@tool
extends System
class_name Tcs

@export var rpm_threshold := 50.0
@export var drop_throttle_speed := 2.0

var _throttle_limit := 1.0


func update(delta: float) -> void:
	if not enabled or transmission == null or transmission.wheels == null:
		return
	var wheels := transmission.wheels
	var free_rpm := 0.0
	var traction_rpm := 0.0
	for wheel in wheels.free_wheels:
		free_rpm += wheel.angular_velocity
	for wheel in wheels.traction_wheels:
		traction_rpm += wheel.angular_velocity
	free_rpm /= len(wheels.free_wheels) / TorqueCurve.TO_RPM
	traction_rpm /= len(wheels.traction_wheels) / TorqueCurve.TO_RPM
	if free_rpm * traction_rpm > 0.0 and absf(free_rpm - traction_rpm) > rpm_threshold:
		_throttle_limit = clampf(_throttle_limit - delta * drop_throttle_speed, 0.0, 1.0)
		indicator = true
	else:
		_throttle_limit = move_toward(_throttle_limit, transmission.motor.input_throttle, delta)
		indicator = false
	transmission.motor.throttle_limit = _throttle_limit


func _on_enable_changed() -> void:
	if transmission != null:
		transmission.motor.throttle_limit = 1.0
