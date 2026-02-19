@tool
extends Node
class_name Differential

enum Type {Auto, Open, Spool}

@export var type := Type.Auto
@export var auto_differential_lock_input_torque := 25.0
@export var auto_differential_slip_max := 0.35

var _wheels: WheelsSim
var _vehicle: RigidBody3D


func _ready() -> void:
	_wheels = get_parent()
	if _wheels == null:
		return
	var transmission := _wheels.transmission
	if transmission == null:
		return
	_vehicle = transmission.get_parent() as RigidBody3D


func apply_torque(delta: float, input_torque: float) -> void:
	if len(_wheels.traction_wheels) != 2:
		return
	if type == Type.Spool:
		var axle_av := get_axle_angular_velocity()
		var axle_inertia := get_axle_inertia()
		var axle_torque := get_axle_torque() * len(_wheels.traction_wheels)
		axle_av += delta * (input_torque + axle_torque) / axle_inertia
		_wheels.traction_wheels[0].torque = (axle_av - _wheels.traction_wheels[0].angular_velocity) * _wheels.traction_wheels[0].inertia / delta
		_wheels.traction_wheels[1].torque = (axle_av - _wheels.traction_wheels[1].angular_velocity) * _wheels.traction_wheels[1].inertia / delta
	elif type == Type.Open:
		var spider_torque := _wheels.traction_wheels[0].torque - _wheels.traction_wheels[1].torque
		var torque0 := input_torque * 0.5 + spider_torque
		var torque1 := input_torque * 0.5 - spider_torque
		_wheels.traction_wheels[0].torque += torque0
		_wheels.traction_wheels[1].torque += torque1
	elif type == Type.Auto:
		var spider_torque := _wheels.traction_wheels[0].torque - _wheels.traction_wheels[1].torque
		var locked_torque := input_torque / auto_differential_lock_input_torque
		var rate := 1.0 - exp(-locked_torque * locked_torque) if locked_torque > 0.0 else 0.0
		var pressure := tanh(rate * (_wheels.traction_wheels[1].angular_velocity - _wheels.traction_wheels[0].angular_velocity))
		var bias := auto_differential_slip_max * 0.5 * pressure
		var open := 1.0 - rate
		var torque0 := input_torque * (0.5 + bias) + spider_torque * open
		var torque1 := input_torque * (0.5 - bias) - spider_torque * open
		_wheels.traction_wheels[0].torque += torque0
		_wheels.traction_wheels[1].torque += torque1
	for wheel in _wheels.traction_wheels:
		wheel.apply_torque(delta)


func get_axle_inertia() -> float:
	var axle_inertia := 0.0
	for wheel in _wheels.traction_wheels:
		axle_inertia += wheel.inertia
	return axle_inertia


func get_axle_angular_velocity() -> float:
	if len(_wheels.traction_wheels) < 1:
		return 0.0
	var axle_av := 0.0
	for wheel in _wheels.traction_wheels:
		axle_av += wheel.angular_velocity
	return axle_av / len(_wheels.traction_wheels)


func get_axle_torque() -> float:
	if len(_wheels.traction_wheels) < 1:
		return 0.0
	var axle_torque := 0.0
	for wheel in _wheels.traction_wheels:
		axle_torque += wheel.torque + wheel.brake_torque
	return axle_torque / len(_wheels.traction_wheels)


func before_simulation(delta: float, input_steering: float) -> void:
	if _vehicle == null:
		return
	var state := PhysicsServer3D.body_get_direct_state(_vehicle.get_rid())
	if state == null:
		return
	var center_of_mass := _vehicle.global_transform * state.center_of_mass_local
	for wheel in _wheels.wheels:
		if wheel.steer_angle_max != 0.0:
			wheel.rotation_degrees.y = input_steering * wheel.steer_angle_max
		wheel.calculate_force(delta, _vehicle, center_of_mass)


func after_simulation(delta: float, free: bool, input_brake: float, input_hand_brake: float) -> void:
	for wheel in _wheels.free_wheels:
		wheel.apply_torque(delta)
	for wheel in _wheels.wheels:
		var brake := maxf(input_brake, input_hand_brake) if wheel.hand_brakable else input_brake
		wheel.update_rotation(delta, free, brake)


func switch() -> void:
	type = ((type as int + 1) % 3) as Type


func get_type_name() -> String:
	if type == Type.Auto:
		return "Auto"
	if type == Type.Open:
		return "Open"
	return "Spool"
