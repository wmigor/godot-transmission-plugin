@tool
extends TransmissionComponent
class_name Clutch

@export_range(0.0, 1.0, 0.001) var input_value := 1.0
@export var max_torque_factor := 1.5
@export var static_friction_factor := 1.25

var clutch_locked := false


func calculate(delta: float) -> void:
	if transmission == null:
		return
	var motor := transmission.motor
	var gear_box := transmission.gear_box
	var differential := transmission.differential
	if motor == null or gear_box == null or differential == null:
		return
	var gear := gear_box.gear
	if input_value <= 0.0 or motor.rpm <= motor.torque_curve.idle_rpm or absf(gear) < 0.01:
		motor.apply_torque(delta, motor.torque)
		differential.apply_torque(delta, 0.0)
		clutch_locked = false
		return
	var clutch_max_torque := get_clutch_max_torque(motor)
	var axle_av := differential.get_axle_angular_velocity() * gear
	var axle_torque := differential.get_axle_torque() / gear
	var av_delta := axle_av - motor.angular_velocity
	var axle_inertia := differential.get_axle_inertia() / gear / gear
	var sync_av := (motor.angular_velocity * motor.inertia + axle_av * axle_inertia) / (motor.inertia + axle_inertia)
	var motor_sync_torque := (sync_av - motor.angular_velocity) * motor.inertia / delta
	var clutch_torque := clampf(signf(av_delta) * clutch_max_torque, -clutch_max_torque, clutch_max_torque)
	var unlock := absf(motor.torque + motor_sync_torque - axle_torque) > clutch_max_torque
	if unlock:
		clutch_locked = false
		motor.apply_torque(delta, motor.torque + clutch_torque)
		differential.apply_torque(delta, -clutch_torque * gear)
		return
	if not clutch_locked:
		var motor_torque := motor.torque + clutch_torque
		var new_motor_av := motor.angular_velocity + delta * motor_torque / motor.inertia
		var new_axle_av := axle_av - delta * clutch_torque / axle_inertia
		var new_av_delta := new_axle_av - new_motor_av
		if new_av_delta * av_delta >= 0.0:
			motor.apply_torque(delta, motor_torque)
			differential.apply_torque(delta, -clutch_torque * gear)
			return
	clutch_locked = true
	motor.apply_torque(delta, motor_sync_torque)
	motor.apply_torque(delta, motor.torque + axle_torque, axle_inertia)
	var differential_sync_torque := (motor.angular_velocity - axle_av) * axle_inertia / delta
	differential.apply_torque(delta, (differential_sync_torque - axle_torque) * gear)




func get_clutch_max_torque(motor: Motor) -> float:
	var clutch_max_dynamic_torque := motor.torque_curve.max_torque * max_torque_factor * input_value * input_value
	var clutch_max_static_torque := clutch_max_dynamic_torque * static_friction_factor
	var clutch_max_torque := clutch_max_static_torque if clutch_locked else clutch_max_dynamic_torque
	return clutch_max_torque
