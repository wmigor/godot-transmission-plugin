@tool
extends Wheels
class_name WheelsSim

@onready var differential := $Differential as Differential

var traction_wheels: Array[Wheel]
var free_wheels: Array[Wheel]
var wheels: Array[Wheel]


func _ready() -> void:
	if transmission == null:
		return
	var vehicle := transmission.get_parent() as RigidBody3D
	if vehicle == null:
		return
	for wheel in vehicle.find_children("*", "Wheel", false):
		wheels.append(wheel)
		if wheel.use_as_traction:
			traction_wheels.append(wheel)
		else:
			free_wheels.append(wheel)


func apply_torque(delta: float, input_torque: float) -> void:
	if differential != null:
		differential.apply_torque(delta, input_torque)


func get_axle_inertia() -> float:
	return differential.get_axle_inertia() if differential != null else 0.0


func get_axle_angular_velocity() -> float:
	return differential.get_axle_angular_velocity() if differential != null else 0.0


func get_axle_torque() -> float:
	return differential.get_axle_torque() if differential != null else 0.0


func before_simulation(delta: float, input_steering: float) -> void:
	if differential != null:
		differential.before_simulation(delta, input_steering)


func after_simulation(delta: float, free: bool, input_brake: float, input_hand_brake: float) -> void:
	if differential != null:
		differential.after_simulation(delta, free, input_brake, input_hand_brake)
