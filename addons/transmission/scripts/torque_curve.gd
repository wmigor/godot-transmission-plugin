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


@export_group("V2")
@export var v2 := false:
	set(value):
		v2 = value
		emit_changed()

@export var displacement_in3 := 97.1:
	set(value):
		displacement_in3 = value
		emit_changed()

@export var ve_peak := 0.88:
	set(value):
		ve_peak = value
		emit_changed()

@export var ve_base := 0.76:
	set(value):
		ve_base = value
		emit_changed()

@export var ve_peak_rpm := 4850.0:
	set(value):
		ve_peak_rpm = value
		emit_changed()

@export var choke_rpm := 7500.0:
	set(value):
		choke_rpm = value
		emit_changed()

@export var fmep_static := 16000.0:
	set(value):
		fmep_static = value
		emit_changed()

@export var fmep_dynamic := 28000.0:
	set(value):
		fmep_dynamic = value
		emit_changed()

@export var friction_exp := 1.45:
	set(value):
		friction_exp = value
		emit_changed()

@export var thermal_eff := 0.3:
	set(value):
		thermal_eff = value
		emit_changed()

@export var afr := 12.6:
	set(value):
		afr = value
		emit_changed()

@export_group("V3")
@export var v3: bool:
	set(value):
		v3 = value
		emit_changed()

const TO_RPM := 60.0 / TAU
const HP_TO_W := 745.7


func get_torque(angular_velocity: float) -> float:
	var rpm := angular_velocity * TO_RPM
	if v3:
		return get_torque_v3(rpm)
	if v2:
		return calculate_torque(rpm)
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


func get_ve(rpm: float) -> float:
	var ve_curve := (ve_peak - ve_base) * exp(-((rpm - ve_peak_rpm) ** 2) / (2 * (max_rpm * 0.3) ** 2))
	var choke := 1.0 / (1.0 + exp((rpm - choke_rpm) / (max_rpm * 0.05)))
	return (ve_base + ve_curve) * choke


func calculate_torque(rpm: float, throttle := 1.0, alt_press := 101325.0) -> float:
	if rpm < idle_rpm:
		return 0.0
	var map_pa := (6.0 * 3386.0) + (throttle * (alt_press * 0.98 - 6.0 * 3386.0))
	var air_density := map_pa / (287.05 * 288.15)
	var disp_m3 := displacement_in3 * 1.6387e-5
	var m_dot_air := (disp_m3 * (rpm / 60.0) * air_density * get_ve(rpm)) / 2.0
	var hp_ind := (m_dot_air / afr * 47.3e6 * thermal_eff) / HP_TO_W
	var speed_ratio := rpm / max_rpm
	var fmep := fmep_static + fmep_dynamic * (speed_ratio ** friction_exp)
	var hp_fric := (fmep * disp_m3 * (rpm / 60.0) / 2.0) / HP_TO_W
	var hp_shaft := maxf(0, hp_ind - hp_fric)
	var torque := (hp_shaft * HP_TO_W) / (rpm * TAU / 60.0) if rpm > 0.0 else 0.0
	return torque


func get_torque_v3(rpm: float, throttle := 1.0) -> float:
	var n := rpm / max_power_rpm
	var t := max_torque_rpm / max_power_rpm
	var b := 0.0
	var d := t / (3.0 * t * t - 3.0 * t)
	var c := (-1.0 - 3 * d) / 2.0
	var a := 1.0 - c - d
	var factor := a * n + b * n * n + c * n * n * n + d * n * n * n * n
	var power := max_power * HP_TO_W * factor
	var av := rpm / TO_RPM
	var torque := power / maxf(1.0, av)
	return torque * throttle
	
