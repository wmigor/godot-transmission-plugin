extends Differential
class_name DifferentialVehicleWheel

@export var steering_angle := 42.0
@export var brake := 50.0

var _transmission: Transmission
var _vehicle: VehicleBody3D

var _traction_wheels: Array[VehicleWheel3D]


func _ready() -> void:
	_transmission = get_parent() as Transmission
	if _transmission == null:
		return
	_vehicle = _transmission.get_parent() as VehicleBody3D
	if _vehicle == null:
		return
	for wheel in _vehicle.find_children("*", "VehicleWheel3D"):
		if wheel.use_as_traction:
			_traction_wheels.append(wheel)


func apply_torque(_delta: float, torque: float) -> void:
	if len(_traction_wheels) > 0 and _vehicle != null:
		var wheel_radius := _traction_wheels[0].wheel_radius
		_vehicle.engine_force = torque / len(_traction_wheels) / wheel_radius


func get_axle_inertia() -> float:
	if len(_traction_wheels) > 0:
		return _vehicle.mass * _traction_wheels[0].wheel_radius
	return 1.0


func get_axle_angular_velocity() -> float:
	if len(_traction_wheels) <= 0:
		return 0.0
	var rpm := 0.0
	for wheel in _traction_wheels:
		rpm += wheel.get_rpm()
	return rpm / len(_traction_wheels) / TorqueCurve.TO_RPM


func get_axle_torque() -> float:
	return 0.0


func update(_delta: float, input_steering: float) -> void:
	if _vehicle != null:
		_vehicle.steering = input_steering * deg_to_rad(steering_angle)


func after_update(_delta: float, _free: bool, input_brake: float, input_hand_brake: float) -> void:
	if _vehicle != null:
		_vehicle.brake = (input_brake * input_hand_brake) * brake
