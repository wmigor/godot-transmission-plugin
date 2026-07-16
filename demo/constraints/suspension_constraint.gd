extends Constraint
class_name SuspensionConstraint

var _car: CustomCar
var _susp: CustomCar.Susp
var _ground: Plane

var _effective_mass: float
var _accumulated_impulse: float

var _origin: Vector3
var _direction: Vector3
var _center: Vector3
var _contact_point: Vector3
var _contact_normal: Vector3
var _length: float
var _contacted: bool
var _j_v: Vector3
var _j_w: Vector3
var _bias: float
var _cfm: float


func _init(car: CustomCar, susp: CustomCar.Susp, ground: Plane) -> void:
	_car = car
	_susp = susp
	_ground = ground


func pre_step(delta: float) -> void:
	_update_parameters()
	if not _contacted:
		return

	var radius := _contact_point - _center
	_j_v = _contact_normal
	_j_w = radius.cross(_contact_normal)

	var error := _length - _susp.rest_length

	var jv := _j_v.dot(_car.body_state.linear_velocity) + _j_w.dot(_car.body_state.angular_velocity)	
	var damping := _susp.damping_bump if jv < 0.0 else _susp.damping_rebound
	_cfm = 1.0 / (delta * _susp.stiffness + damping)
	var erp := (delta * _susp.stiffness) / (delta * _susp.stiffness + damping)
	
	var inv_inertial_world := _car.body_state.inverse_inertia_tensor
	var K := _j_v.dot(_j_v) * _car.body_state.inverse_mass + _j_w.dot(inv_inertial_world * _j_w)
	_effective_mass = 1.0 / (K + _cfm)
	_bias = -(erp / delta) * error
	
	_car.body_state.apply_central_impulse(_j_v * _accumulated_impulse)
	_car.body_state.apply_torque_impulse(_j_w * _accumulated_impulse)



func step(_delta: float) -> void:
	if not _contacted:
		return

	var jv := _j_v.dot(_car.body_state.linear_velocity) + _j_w.dot(_car.body_state.angular_velocity)
	var lambda := (_bias - jv - _cfm * _accumulated_impulse) * _effective_mass

	var old_accumulated := _accumulated_impulse
	_accumulated_impulse = maxf(_accumulated_impulse + lambda, 0.0)
	lambda = _accumulated_impulse - old_accumulated

	_car.body_state.apply_central_impulse(_j_v * lambda)
	_car.body_state.apply_torque_impulse(_j_w * lambda)


func _update_parameters() -> void:
	_center = _car.transform * _car.body_state.center_of_mass_local
	_origin = _car.global_transform * _susp.pos
	_direction = _car.global_basis * _susp.direction
	var point = _ground.intersects_ray(_origin, _direction)
	if point != null:
		_contact_point = point
		var distance := _origin.distance_to(_contact_point)
		_length = minf(_susp.rest_length, distance)
		_contact_normal = _ground.normal
		_contacted = distance <= _susp.rest_length
	else:
		_contacted = false
		_length = _susp.rest_length
	if not _contacted:
		_accumulated_impulse = 0.0
