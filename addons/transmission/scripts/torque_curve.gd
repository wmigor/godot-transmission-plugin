@tool
extends Resource
class_name TorqueCurve

@export var idle_torque := 80.0:
	set(value):
		idle_torque = value
		emit_changed()

@export var max_torque := 151.0:
	set(value):
		max_torque = value
		emit_changed()

@export var max_rpm := 6500.0:
	set(value):
		max_rpm = value
		emit_changed()

@export var idle_rpm := 800.0:
	set(value):
		idle_rpm = value
		emit_changed()


@export_range(0.0, 1.0, 0.01) var peak_torque_rpm := 0.75:
	set(value):
		peak_torque_rpm = value
		emit_changed()


@export var peak_torque_power := 2.0:
	set(value):
		peak_torque_power = value
		emit_changed()


@export_range(0.0, 1.0, 0.01) var drop_torque := 0.8:
	set(value):
		drop_torque = value
		emit_changed()


@export var drop_torque_power := 2.0:
	set(value):
		drop_torque_power = value
		emit_changed()


@export var brake_linear_factor := 0.1:
	set(value):
		brake_linear_factor = value
		emit_changed()

@export var brake_factor := 0.1:
	set(value):
		brake_factor = value
		emit_changed()


const TO_RPM := 60.0 / TAU
const HP_TO_W := 745.7


func get_torque(angular_velocity: float) -> float:
	var rpm := angular_velocity * TO_RPM
	if rpm <= idle_rpm:
		return idle_torque
	var mid_rpm := max_rpm * peak_torque_rpm
	if rpm <= mid_rpm:
		var w := 1.0 - (rpm - idle_rpm) / (mid_rpm - idle_rpm)
		return lerpf(idle_torque, max_torque, 1.0 - pow(w, peak_torque_power))
	else:
		var w := (rpm - mid_rpm) / (max_rpm - mid_rpm)
		return lerpf(max_torque, max_torque * drop_torque, pow(w, drop_torque_power))


func get_power(angular_velocity: float) -> float:
	return angular_velocity * get_torque(angular_velocity)
