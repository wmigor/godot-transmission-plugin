@tool
extends Resource
class_name TorqueCurve


@export_group("Points")
@export_custom(PROPERTY_HINT_NONE, "suffix:RPM")
var idle_rpm := 800.0:
	set(value):
		idle_rpm = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:Nm")
var idle_torque := 70.0:
	set(value):
		idle_torque = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:RPM")
var effective_rpm := 1500.0:
	set(value):
		effective_rpm = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:Nm")
var effective_torque := 120.0:
	set(value):
		effective_torque = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:RPM")
var max_torque_rpm := 4300.0:
	set(value):
		max_torque_rpm = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:Nm")
var max_torque := 155.0:
	set(value):
		max_torque = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:RPM")
var max_power_rpm := 6300.0:
	set(value):
		max_power_rpm = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:HP")
var max_power := 123.0:
	set(value):
		max_power = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:RPM")
var max_rpm := 6500.0:
	set(value):
		max_rpm = value
		emit_changed()


@export_custom(PROPERTY_HINT_NONE, "suffix:Nm")
var max_rpm_torque := 132.0:
	set(value):
		max_rpm_torque = value
		emit_changed()


@export_group("Shapes")
@export var idle_shape := 1.4:
	set(value):
		idle_shape = value
		emit_changed()


@export var effective_shape := 2.0:
	set(value):
		effective_shape = value
		emit_changed()


@export var power_shape := 2.0:
	set(value):
		power_shape = value
		emit_changed()


@export var low_shape := 1.4:
	set(value):
		low_shape = value
		emit_changed()


@export_group("Brake")
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
	if rpm <= effective_rpm:
		var w := 1.0 - (rpm - idle_rpm) / (effective_rpm - idle_rpm)
		return lerpf(idle_torque, effective_torque, 1.0 - pow(w, idle_shape))
	if rpm <= max_torque_rpm:
		var w := 1.0 - (rpm - effective_rpm) / (max_torque_rpm - effective_rpm)
		return lerpf(effective_torque, max_torque, 1.0 - pow(w, effective_shape))
	var max_power_w := max_power * HP_TO_W
	var max_power_av := max_power_rpm / TO_RPM
	var torque_at_max_power := max_power_w / max_power_av
	if rpm <= max_power_rpm:
		var w := (rpm - max_torque_rpm) / (max_power_rpm - max_torque_rpm)
		return lerpf(max_torque, torque_at_max_power, pow(w, power_shape))
	if rpm <= max_rpm:
		var w := (rpm - max_power_rpm) / (max_rpm - max_power_rpm)
		return lerpf(torque_at_max_power, max_rpm_torque, pow(w, low_shape))
	return 0.0


func get_power(angular_velocity: float) -> float:
	return angular_velocity * get_torque(angular_velocity)
