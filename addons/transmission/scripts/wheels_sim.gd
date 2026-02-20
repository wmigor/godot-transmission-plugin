@tool
extends Wheels
class_name WheelsSim

@onready var differential := $Differential as Differential

var traction_wheels: Array[Wheel]
var free_wheels: Array[Wheel]
var wheels: Array[Wheel]
var _vehicle: RigidBody3D


func _ready() -> void:
	if transmission == null:
		return
	_vehicle = transmission.get_parent()
	if _vehicle == null:
		return
	_find_wheels()


func _find_wheels() -> void:
	traction_wheels.clear()
	wheels.clear()
	free_wheels.clear()
	if differential != null:
		differential.find_wheels(traction_wheels)
		wheels.append_array(traction_wheels)
	for wheel in _vehicle.find_children("*", "Wheel", false):
		if wheel not in wheels:
			wheels.append(wheel)
			free_wheels.append(wheel)


func apply_torque(delta: float, torque: float) -> void:
	if differential != null:
		differential.shaft.torque = torque
		differential.apply_torque(delta)


func get_axle_inertia() -> float:
	return differential.shaft.inertia if differential != null else 0.0


func get_axle_angular_velocity() -> float:
	return differential.shaft.angular_velocity if differential != null else 0.0


func get_axle_torque() -> float:
	return differential.shaft.torque if differential != null else 0.0


func before_simulation(delta: float, input_steering: float) -> void:
	if _vehicle == null:
		return
	var state := PhysicsServer3D.body_get_direct_state(_vehicle.get_rid())
	if state == null:
		return
	var center_of_mass := _vehicle.global_transform * state.center_of_mass_local
	for wheel in wheels:
		if wheel.steer_angle_max != 0.0:
			wheel.rotation_degrees.y = input_steering * wheel.steer_angle_max
		wheel.calculate_force(delta, _vehicle, center_of_mass)
	if differential != null:
		differential.update_shafts()


func after_simulation(delta: float, free: bool, input_brake: float, input_hand_brake: float) -> void:
	for wheel in free_wheels:
		wheel.shaft.torque = 0.0
		wheel.apply_torque(delta)
	for wheel in wheels:
		var brake := maxf(input_brake, input_hand_brake) if wheel.hand_brakable else input_brake
		wheel.update_rotation(delta, free, brake)
