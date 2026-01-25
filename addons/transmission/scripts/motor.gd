extends Node
class_name Motor

@export var idle_torque := 80.0
@export var max_torque := 151.0
@export var max_rpm := 6500.0
@export var idle_rpm := 500.0
@export var inertia := 0.2
@export var brake_linear_factor := 0.2
@export var brake_factor := 0.2

const TO_RPM := 60.0 / TAU
const HP_TO_W := 745.7

var angular_velocity: float
var torque: float

var rpm: float:
	get: return angular_velocity * TO_RPM
	set(value): angular_velocity = value / TO_RPM


func update_torque(throttle: float) -> void:
	if rpm >= max_rpm:
		throttle = 0.0
	var back_torque := angular_velocity * brake_linear_factor
	torque = (get_nominal_torque() + back_torque) * throttle - back_torque
	if throttle <= 0.0:
		torque -= max_torque * brake_factor


func get_nominal_torque() -> float:
	if rpm <= idle_rpm:
		return idle_torque
	var mid_rpm := max_rpm * 0.75
	if rpm <= mid_rpm:
		var w := 1.0 - (rpm - idle_rpm) / (mid_rpm - idle_rpm)
		return lerpf(idle_torque, max_torque, 1.0 - w * w)
	else:
		var w := (rpm - mid_rpm) / (max_rpm - mid_rpm)
		return lerpf(max_torque, max_torque * 0.95, w * w)


func get_nominal_hp() -> float:
	return get_nominal_torque() * angular_velocity / HP_TO_W
