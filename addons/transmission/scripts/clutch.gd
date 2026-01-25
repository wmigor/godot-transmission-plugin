extends Node
class_name Clutch

@export var max_torque_factor := 1.5
@export var input_value := 1.0

var clutch_locked := false


func calculate_output_torque(delta: float, motor: Motor, gear: float, axle_av: float, axle_inertia: float, axle_torque: float) -> float:
	if input_value <= 0.0 or motor.rpm <= motor.idle_rpm:
		motor.angular_velocity += delta * motor.torque / motor.inertia
		motor.rpm = max(motor.rpm, motor.idle_rpm)
		clutch_locked = false
		return 0.0 
	var clutch_max_torque := motor.max_torque * max_torque_factor
	var clutch_capacity := clutch_max_torque * input_value * input_value
	var av_delta := axle_av - motor.angular_velocity
	if absf(av_delta) > 5 and not clutch_locked or clutch_locked and absf(motor.torque - axle_torque / gear) > clutch_capacity * 1.2:
		clutch_locked = false
		var clutch_torque := clampf(signf(av_delta) * clutch_capacity, -clutch_capacity, clutch_capacity)
		motor.angular_velocity += delta * (motor.torque + clutch_torque) / motor.inertia
		motor.rpm = max(motor.rpm, motor.idle_rpm)
		return -clutch_torque * gear
	motor.angular_velocity = (motor.angular_velocity * motor.inertia + axle_av * axle_inertia) / (motor.inertia + axle_inertia)
	clutch_locked = true
	motor.angular_velocity += delta * (motor.torque * gear + axle_torque) / (motor.inertia + axle_inertia)
	motor.rpm = max(motor.rpm, motor.idle_rpm)
	var output_torque := (motor.angular_velocity - axle_av) * axle_inertia / delta
	return output_torque
