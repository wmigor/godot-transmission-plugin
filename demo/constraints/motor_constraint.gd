extends Constraint
class_name MotorConstraint

var _shaft: Shaft
var _torque_curve: TorqueCurve

var _effective_mass: float
var _accumulated_impulse: float
var _bias := 0.0

var input_throttle := 1.0


func _init(shaft: Shaft, torque_curve: TorqueCurve) -> void:
	_shaft = shaft
	_torque_curve = torque_curve


func pre_step(_delta: float) -> void:
	_effective_mass = 1.0 / _shaft.inv_inertia
	var rpm := _shaft.rpm
	if rpm > _torque_curve.max_rpm:
		_bias = 0.0
	else:
		var target_av := _torque_curve.max_rpm / TorqueCurve.TO_RPM
		_bias = target_av

	_shaft.apply_torque_impulse(_accumulated_impulse)


func step(delta: float) -> void:
	var jv := _shaft.angular_velocity
	var lambda := (_bias - jv) * _effective_mass
	var current_rpm := _shaft.rpm
	var available_torque := _get_torque()
	var current_torque := available_torque * input_throttle
	if current_rpm < _torque_curve.idle_rpm:
		var idle_assist := (_torque_curve.idle_rpm - current_rpm) / _torque_curve.idle_rpm
		current_torque = maxf(current_torque, available_torque * idle_assist)
	var max_impulse := current_torque * delta
	
	var old_accumulated = _accumulated_impulse
	_accumulated_impulse = clampf(_accumulated_impulse + lambda, 0.0, max_impulse)
	lambda = _accumulated_impulse - old_accumulated
	_shaft.apply_torque_impulse(lambda)


func _get_torque() -> float:
	var throttle := clampf(input_throttle, 0.0, 1.0)
	if _shaft.rpm >= _torque_curve.max_rpm:
		throttle = 0.0
	var back_torque := _shaft.angular_velocity * _torque_curve.brake_linear_factor
	var torque := (_torque_curve.get_torque(_shaft.angular_velocity) + back_torque) * throttle - back_torque
	if throttle <= 0.0:
		torque -= _torque_curve.max_torque * _torque_curve.brake_factor
	return torque
