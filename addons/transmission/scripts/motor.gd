extends Node
class_name Motor

@export_range(0.0, 1.0, 0.001) var input_throttle := 0.0

@export var torque_curve := TorqueCurve.new()
@export var inertia := 0.2

var angular_velocity: float
var torque: float

var rpm: float:
	get: return angular_velocity * TorqueCurve.TO_RPM
	set(value): angular_velocity = value / TorqueCurve.TO_RPM


func update_torque() -> void:
	var throttle := input_throttle
	if rpm >= torque_curve.max_rpm:
		throttle = 0.0
	var back_torque := angular_velocity * torque_curve.brake_linear_factor
	torque = (get_nominal_torque() + back_torque) * throttle - back_torque
	if throttle <= 0.0:
		torque -= torque_curve.max_torque * torque_curve.brake_factor


func apply_torque(delta: float, torque: float, extra_inertia := 0.0) -> void:
	angular_velocity += torque * delta / (inertia + extra_inertia)
	rpm = maxf(torque_curve.idle_rpm, rpm)


func get_nominal_torque() -> float:
	return torque_curve.get_torque(angular_velocity)
