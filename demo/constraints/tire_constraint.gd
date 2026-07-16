extends Constraint
class_name TireConstraint

var angle: float

var _car: CustomCar
var _susp: CustomCar.Susp
var _ground: Plane
var _wheel: Shaft
var _wheel_radius: float

var _effective_mass: float
var _accumulated_impulse: float

var _origin: Vector3
var _direction: Vector3
var _center: Vector3
var _contact_point: Vector3
var _contact_normal: Vector3
var _length: float
var _contacted: bool
var _force: float
var _j_v: Vector3
var _j_w_car: Vector3
var _j_w_wheel: float
var _cfm: float


func _init(car: CustomCar, susp: CustomCar.Susp, ground: Plane, wheel: Shaft, wheel_radius: float) -> void:
	_car = car
	_susp = susp
	_ground = ground
	_wheel = wheel
	_wheel_radius = wheel_radius


func pre_step(delta: float) -> void:
	_update_parameters()
	if not _contacted:
		return

	var radius := _contact_point - _center

	var car_fwd := (-_car.global_transform.basis.z.normalized()).rotated(_direction, angle)
	var fwd_on_ground := (car_fwd - _contact_normal * car_fwd.dot(_contact_normal)).normalized()
	var v_car_point := _car.body_state.linear_velocity + _car.body_state.angular_velocity.cross(radius)
	
	var v_wheel_linear := fwd_on_ground * (_wheel.angular_velocity * _wheel_radius)
	var v_total_slip := v_car_point - v_wheel_linear
	var v_slip_tangent := v_total_slip - _contact_normal * v_total_slip.dot(_contact_normal)

	var slip_direction := fwd_on_ground
	if v_slip_tangent.length_squared() > 0.0001:
		slip_direction = v_slip_tangent.normalized()

	_j_v = slip_direction
	_j_w_car = radius.cross(slip_direction)
	_j_w_wheel = -_wheel_radius * slip_direction.dot(fwd_on_ground)

	_cfm = 1.0 / (delta * _susp.tire_stiffness)
	var inv_I_car := _car.body_state.inverse_inertia_tensor
	
	var K := _j_v.dot(_j_v) * _car.body_state.inverse_mass \
		   + _j_w_car.dot(inv_I_car * _j_w_car) \
		   + (_j_w_wheel * _j_w_wheel) * _wheel.inv_inertia

	_effective_mass = 1.0 / (K + _cfm)

	_car.body_state.apply_central_impulse(_j_v * _accumulated_impulse)
	_car.body_state.apply_torque_impulse(_j_w_car * _accumulated_impulse)
	_wheel.apply_torque_impulse(_j_w_wheel * _accumulated_impulse)


func step(_delta: float) -> void:
	if not _contacted:
		return

	var max_friction_impulse := _susp.friction_coefficient * _susp.accumulated_impulse

	var jv := _j_v.dot(_car.body_state.linear_velocity) \
			 + _j_w_car.dot(_car.body_state.angular_velocity) \
			 + _j_w_wheel * _wheel.angular_velocity

	var lambda := (0.0 - jv - _cfm * _accumulated_impulse) * _effective_mass
	
	var old_accumulated := _accumulated_impulse
	_accumulated_impulse = clampf(_accumulated_impulse + lambda, -max_friction_impulse, max_friction_impulse)
	lambda = _accumulated_impulse - old_accumulated

	_car.body_state.apply_central_impulse(_j_v * lambda)
	_car.body_state.apply_torque_impulse(_j_w_car * lambda)
	_wheel.apply_torque_impulse(_j_w_wheel * lambda)


func _update_parameters() -> void:
	_center = _car.transform * _car.body_state.center_of_mass_local
	_origin = _car.transform * _susp.pos
	_direction = _car.basis * _susp.direction
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
		_force = 0.0
		_accumulated_impulse = 0.0
	else:
		_force = maxf(_susp.stiffness * (_susp.rest_length - _length), 0.0)
