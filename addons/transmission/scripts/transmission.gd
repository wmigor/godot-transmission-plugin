extends Node
class_name Transmission

@export var wheel_inertia := 1.2
@export var input_throttle := 0.0

@onready var motor := $Motor as Motor
@onready var gear_box := $GearBox as GearBox

var _vehicle: VehicleBody3D
var _traction_wheels: Array[VehicleWheel3D]


func _enter_tree() -> void:
	_vehicle = get_parent() as VehicleBody3D


func _exit_tree() -> void:
	_vehicle = null


func _ready() -> void:
	if _vehicle == null:
		return
	for wheel in _vehicle.find_children("*", "VehicleWheel3D"):
		if wheel.use_as_traction:
			_traction_wheels.append(wheel)


func _physics_process(delta: float) -> void:
	if _vehicle == null or motor == null:
		return
	var gear := gear_box.gear
	var axle_inertia := wheel_inertia * len(_traction_wheels)
	var clutch := 0.0 if motor.rpm <= motor.idle_rpm else 1.0
	var axle_av := _get_axle_angular_velocity()
	motor.update_torque(input_throttle)
	var motor_reaction := motor.update_rotation(delta, gear, axle_av * gear, axle_inertia / gear, clutch)
	var reaction_torque := len(_traction_wheels) * (motor_reaction - axle_av) * axle_inertia / delta
	_vehicle.engine_force = clutch * (motor.torque * gear + reaction_torque) / len(_traction_wheels) / _traction_wheels[0].wheel_radius if len(_traction_wheels) > 0 else 0.0


func _get_axle_angular_velocity() -> float:
	if len(_traction_wheels) <= 0:
		return 0.0
	var rpm := 0.0
	for wheel in _traction_wheels:
		rpm += wheel.get_rpm()
	return rpm / len(_traction_wheels) / Motor.TO_RPM
