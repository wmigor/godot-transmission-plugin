extends Differential
class_name DifferentialSim

@export var auto_differential := true
@export var auto_differential_lock_input_torque := 25.0
@export var auto_differential_slip_max := 0.35

var _vehicle: RigidBody3D
var _traction_wheels: Array[Wheel]
var _free_wheels: Array[Wheel]
var _wheels: Array[Wheel]


func _ready() -> void:
	var transmission := get_parent() as Transmission
	if transmission == null:
		return
	_vehicle = transmission.get_parent() as RigidBody3D
	if _vehicle == null:
		return
	for wheel in _vehicle.find_children("*", "Wheel", false):
		_wheels.append(wheel)
		if wheel.use_as_traction:
			_traction_wheels.append(wheel)
		else:
			_free_wheels.append(wheel)


func apply_torque(delta: float, input_torque: float) -> void:
	if len(_traction_wheels) != 2:
		return
	if not auto_differential:
		var spider_torque := _traction_wheels[0].torque - _traction_wheels[1].torque
		var torque0 := input_torque * 0.5 + spider_torque
		var torque1 := input_torque * 0.5 - spider_torque
		_traction_wheels[0].torque += torque0
		_traction_wheels[1].torque += torque1
	else:
		var spider_torque := _traction_wheels[0].torque - _traction_wheels[1].torque
		var locked_torque := input_torque / auto_differential_lock_input_torque
		var rate := 1.0 - exp(-locked_torque * locked_torque) if locked_torque > 0.0 else 0.0
		var pressure := tanh(rate * (_traction_wheels[1].angular_velocity - _traction_wheels[0].angular_velocity))
		var bias := auto_differential_slip_max * 0.5 * pressure
		var open := 1.0 - rate
		var torque0 := input_torque * (0.5 + bias) + spider_torque * open
		var torque1 := input_torque * (0.5 - bias) - spider_torque * open
		_traction_wheels[0].torque += torque0
		_traction_wheels[1].torque += torque1
	for wheel in _traction_wheels:
		wheel.apply_torque(delta)


func get_axle_inertia() -> float:
	var axle_inertia := 0.0
	for wheel in _traction_wheels:
		axle_inertia += wheel.inertia
	return axle_inertia


func get_axle_angular_velocity() -> float:
	if len(_traction_wheels) < 1:
		return 0.0
	var axle_av := 0.0
	for wheel in _traction_wheels:
		axle_av += wheel.angular_velocity
	return axle_av / len(_traction_wheels)


func get_axle_torque() -> float:
	if len(_traction_wheels) < 1:
		return 0.0
	var axle_torque := 0.0
	for wheel in _traction_wheels:
		axle_torque += wheel.torque + wheel.brake_torque
	return axle_torque / len(_traction_wheels)


func update(delta: float, input_steering: float) -> void:
	if _vehicle == null:
		return
	var state := PhysicsServer3D.body_get_direct_state(_vehicle.get_rid())
	if state == null:
		return
	var center_of_mass := _vehicle.global_transform * state.center_of_mass_local
	for wheel in _wheels:
		if wheel.steer_angle_max != 0.0:
			wheel.rotation_degrees.y = input_steering * wheel.steer_angle_max
		wheel.calculate_force(delta, _vehicle, center_of_mass)


func after_update(delta: float, free: bool, input_brake: float, input_hand_brake: float) -> void:
	for wheel in _free_wheels:
		wheel.apply_torque(delta)
	for wheel in _wheels:
		var brake := maxf(input_brake, input_hand_brake) if wheel.hand_brakable else input_brake
		wheel.update_rotation(delta, free, brake)
