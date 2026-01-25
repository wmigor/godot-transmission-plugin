extends Node
class_name Transmission

@export var input_throttle := 0.0

@onready var motor := $Motor as Motor
@onready var gear_box := $GearBox as GearBox
@onready var clutch := $Clutch as Clutch

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
	if _vehicle == null or motor == null or len(_traction_wheels) < 1:
		return
	var wheel_radius := _traction_wheels[0].wheel_radius
	var gear := gear_box.gear
	var axle_inertia := _vehicle.mass * wheel_radius
	var axle_av := _get_axle_angular_velocity()
	motor.update_torque(input_throttle)
	var torque := clutch.calculate_output_torque(delta, motor, gear, axle_av * gear, axle_inertia / gear, 0.0)
	_vehicle.engine_force = torque / len(_traction_wheels) / wheel_radius


func _get_axle_angular_velocity() -> float:
	if len(_traction_wheels) <= 0:
		return 0.0
	var rpm := 0.0
	for wheel in _traction_wheels:
		rpm += wheel.get_rpm()
	return rpm / len(_traction_wheels) / Motor.TO_RPM
