extends System
class_name Tcs

@export var rpm_threshold := 50.0
@export var drop_throttle_speed := 2.0

var _throttle_limit := 1.0
var _transmission: Transmission
var _free_wheels: Array[Wheel]
var _traction_wheels: Array[Wheel]


func _ready() -> void:
	_transmission = get_parent() as Transmission
	for wheel in _transmission.get_parent().find_children("*", "Wheel"):
		if wheel.use_as_traction:
			_traction_wheels.append(wheel)
		else:
			_free_wheels.append(wheel)


func update(delta: float) -> void:
	if not enabled or len(_free_wheels) < 1 or len(_traction_wheels) < 1 or _transmission == null:
		return
	var free_rpm := 0.0
	var traction_rpm := 0.0
	for wheel in _free_wheels:
		free_rpm += wheel.angular_velocity
	for wheel in _traction_wheels:
		traction_rpm += wheel.angular_velocity
	free_rpm /= len(_free_wheels) / TorqueCurve.TO_RPM
	traction_rpm /= len(_traction_wheels) / TorqueCurve.TO_RPM
	if free_rpm * traction_rpm > 0.0 and absf(free_rpm - traction_rpm) > rpm_threshold:
		_throttle_limit = clampf(_throttle_limit - delta * drop_throttle_speed, 0.0, 1.0)
		indicator = true
	else:
		_throttle_limit = move_toward(_throttle_limit, _transmission.motor.input_throttle, delta)
		indicator = false
	_transmission.motor.throttle_limit = _throttle_limit


func _on_enable_changed() -> void:
	if _transmission != null:
		_transmission.motor.throttle_limit = 1.0
