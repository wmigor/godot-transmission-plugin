extends Node
class_name Clutch

@export_range(0.0, 1.0, 0.001) var input_value := 1.0
@export var max_torque_factor := 1.5

var clutch_locked := false


func calculate(delta: float, motor: Motor, differential: Differential, gear: float) -> void:
	if input_value <= 0.0 or motor.rpm <= motor.torque_curve.idle_rpm:
		motor.apply_torque(delta, motor.torque)
		differential.apply_torque(0.0)
		clutch_locked = false
		return
	var clutch_max_torque := motor.torque_curve.max_torque * max_torque_factor * input_value * input_value
	var axle_av := differential.get_axle_angular_velocity() * gear
	var axle_torque := differential.get_axle_torque() / gear
	var av_delta := axle_av - motor.angular_velocity
	var axle_inertia := differential.get_axle_inertia() / gear / gear
	if not clutch_locked or clutch_locked and absf(motor.torque - axle_torque) > clutch_max_torque:
		clutch_locked = false
		var clutch_torque := clampf(signf(av_delta) * clutch_max_torque, -clutch_max_torque, clutch_max_torque)
		var motor_torque := motor.torque + clutch_torque
		var new_motor_av := motor.angular_velocity + delta * motor_torque / motor.inertia
		var new_differential_av := axle_av - delta * clutch_torque / axle_inertia
		var new_av_delta := new_differential_av - new_motor_av
		if new_av_delta * av_delta >= 0.0:
			motor.apply_torque(delta, motor_torque)
			differential.apply_torque(-clutch_torque * gear)
			return
	motor.angular_velocity = (motor.angular_velocity * motor.inertia + axle_av * axle_inertia) / (motor.inertia + axle_inertia)
	clutch_locked = true
	motor.apply_torque(delta, motor.torque + axle_torque, motor.inertia + axle_inertia)
	motor.rpm = max(motor.rpm, motor.torque_curve.idle_rpm)
	differential.apply_torque(((motor.angular_velocity - axle_av) * axle_inertia / delta - axle_torque) * gear)
