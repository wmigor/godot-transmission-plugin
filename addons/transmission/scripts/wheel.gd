extends Node3D
class_name Wheel

@export_category("Wheel")
@export var use_as_traction := false
@export var steer_angle_max := 0.0
@export var hand_brakable: bool
@export var radius := 0.316
@export var inertia := 1.2
@export var tire_model_longitudinal: TireModel
@export var tire_model_lateral: TireModel
@export var max_brake_torque := 2000.0

@export_category("Spring")
@export var spring_stiffness := 20000.0
@export var spring_damping_compress := 4000.0
@export var spring_damping_relax := 4000.0
@export var spring_length := 1.0
@export var spring_mass := 50.0

@onready var _ray_cast := RayCast3D.new()

var angular_velocity: float
var torque: float
var brake_torque: float
var _last_forward_force: float
var _last_right_force_filter: float
var _forward_velocity: float
var _old_av: float
var _spring_velocity: float
var _spring_acceleration: float
var _spring_force: float
var compress: float
var stabilizer_force: float


func _ready() -> void:
	var body := _get_parent_body()
	_ray_cast.add_exception(body)
	_ray_cast.position = body.to_local(global_position) + Vector3.UP * spring_length
	_ray_cast.target_position = Vector3.DOWN * spring_length
	body.add_child.call_deferred(_ray_cast)


func _get_parent_body() -> PhysicsBody3D:
	var parent = get_parent()
	while parent != null:
		if parent is PhysicsBody3D:
			return parent
		parent = parent.get_parent()
	return null


func _get_spring_direction() -> Vector3:
	var vector := _ray_cast.global_position - _ray_cast.to_global(_ray_cast.target_position)
	vector = vector.normalized()
	return vector


func get_contact_point() -> Vector3:
	if _ray_cast.is_colliding():
		return _ray_cast.get_collision_point()
	return _ray_cast.global_position + _get_spring_direction() * radius


func calculate_force(delta: float, velocity: Vector3) -> Vector3:
	var spring_direction := _get_spring_direction()
	var normal := _ray_cast.get_collision_normal() if _ray_cast.is_colliding() else spring_direction
	var right := global_basis.x
	var forward := normal.cross(right)
	var spring_force := _calculate_spring_force_simple(delta, spring_direction)
	var tyre_force := _calculate_tyre_force(velocity, spring_force, forward)
	torque = -tyre_force.dot(forward) * radius
	return tyre_force + spring_force * spring_direction


func _calculate_tyre_force(velocity: Vector3, spring_force: float, forward: Vector3) -> Vector3:
	var right := global_basis.x
	_forward_velocity = velocity.dot(forward)
	var right_velocity := velocity.dot(right)
	var slip_angle := calculate_slip_angle(_forward_velocity, right_velocity)
	var slip_ratio := calculate_slip_ratio(_forward_velocity)

	var f := _get_tire_forces(slip_angle, slip_ratio, spring_force) if spring_force > 0.0 else Vector2.ZERO
	if spring_force <= 0.0:
		_last_forward_force = 0.0
		_last_forward_force = 0.0
	var forward_force := _last_forward_force + 0.5 * (f.x - _last_forward_force)
	var right_force := _last_right_force_filter + 0.5 * (f.y - _last_right_force_filter)
	_last_forward_force = forward_force
	_last_right_force_filter = right_force

	return forward_force * forward + right_force * right


func _get_tire_forces(slip_angle: float, slip_ratio: float, weight: float) -> Vector2:
	if tire_model_longitudinal == null or tire_model_lateral == null:
		return Vector2.ZERO
	var fx := tire_model_longitudinal.get_value(slip_ratio) * weight
	var fy := tire_model_lateral.get_value(slip_angle) * weight
	var fx_max := tire_model_longitudinal.peak * weight
	var fy_max := tire_model_lateral.peak * weight
	var elliptic_value := fx * fx / (fx_max * fx_max) + fy * fy / (fy_max * fy_max)
	if elliptic_value > 1.0:
		return Vector2(fx, fy) / sqrt(elliptic_value)
	return Vector2(fx, fy)


func apply_torque(delta: float) -> void:
	angular_velocity += delta * torque / inertia


func update_rotation(delta: float, free: bool, brake: float) -> void:
	brake_torque = -signf(angular_velocity) * brake * max_brake_torque
	if free and (absf(brake_torque) > 0.0 or not use_as_traction):
		free = false
	if free and (_forward_velocity - angular_velocity * radius) * (_forward_velocity - _old_av * radius) < 0.0:
		angular_velocity = _forward_velocity / radius
		_old_av = angular_velocity
	else:
		var old_av := angular_velocity
		angular_velocity = _old_av + (angular_velocity - _old_av) * 0.5
		_old_av = old_av

	var dv := delta * brake_torque / inertia
	if absf(dv) > absf(angular_velocity):
		dv = -angular_velocity
	angular_velocity += dv

	for i in get_child_count():
		var child := get_child(i) as Node3D
		if child != null:
			child.rotate_x(-angular_velocity * delta)


func _calculate_spring_force_x(delta: float, spring_direction: Vector3) -> float:
	var new_compress := compress + _spring_velocity * delta
	var collision_compress := _get_collision_compress(spring_direction)
	var contact := collision_compress > 0.0 and collision_compress >= new_compress
	if contact:
		new_compress = collision_compress
	var old_compres := compress
	var old_v := _spring_velocity
	compress = new_compress
	_spring_velocity = (new_compress - old_compres) / delta
	_spring_acceleration = (_spring_velocity - old_v) / delta
	
	var damping := spring_damping_compress if _spring_velocity > 0.0 else spring_damping_relax
	var force := -compress * spring_stiffness - clampf(_spring_velocity, -10.0, 10.0) * damping# - _spring_acceleration * spring_mass
	
	if _spring_force * force < 0.0:
		force = 0.0
		_spring_velocity = 0.0
		_spring_acceleration = 0.0
	_spring_force = force

	global_position = _ray_cast.global_position - spring_direction * (spring_length - compress - radius)
	_spring_velocity += force / spring_mass * delta
	if not _ray_cast.is_colliding():
		return 0.0
	return maxf(0.0, -force)


func _calculate_spring_force(delta: float, spring_direction: Vector3) -> float:
	var old := compress
	var collision_compress := _get_collision_compress(spring_direction)
	var contact := collision_compress > 0.0 and collision_compress >= compress
	if contact:
		compress = collision_compress
		_spring_velocity = (compress - old) / delta
	global_position = _ray_cast.global_position - spring_direction * (spring_length - compress - radius)
	var damping := spring_damping_compress if _spring_velocity > 0.0 else spring_damping_relax
	var force := -compress * spring_stiffness - clampf(_spring_velocity, -10.0, 10.0) * damping
	if _spring_force * force < 0.0:
		force = 0.0
		_spring_velocity = 0.0
	_spring_force = force
	_spring_velocity += force / spring_mass * delta
	compress += _spring_velocity * delta
	if contact and compress < collision_compress:
		compress = collision_compress
	if not _ray_cast.is_colliding():
		return 0.0
	return maxf(0.0, -force)


func _calculate_spring_force_simple(delta: float, spring_direction: Vector3) -> float:
	var collision_compress := _get_collision_compress(spring_direction)
	var contact := collision_compress > 0.0
	if contact:
		_spring_velocity = clampf((collision_compress - compress) / delta, -10.0, 10.0)
		compress = collision_compress
	else:
		compress = move_toward(compress, 0.0, delta)
		_spring_velocity = 0.0
	global_position = _ray_cast.global_position - spring_direction * (spring_length - compress - radius)
	var damping := spring_damping_compress if _spring_velocity > 0.0 else spring_damping_relax
	var force := -stabilizer_force - compress * spring_stiffness - _spring_velocity * damping
	_spring_force = force
	if not _ray_cast.is_colliding():
		return 0.0
	return maxf(0.0, -force)


func _get_collision_compress(spring_direction: Vector3) -> float:
	if not _ray_cast.is_colliding():
		return 0.0
	var collider := _ray_cast.get_collider() as Node3D
	if collider == null:
		return 0.0
	var vector := _ray_cast.get_collision_point() - _ray_cast.global_position
	return maxf(0.0, spring_length + vector.dot(spring_direction))


static func calculate_slip_angle(forward_velocity: float, right_velocity: float) -> float:
	if absf(forward_velocity) < 0.0000001 and absf(right_velocity) < 0.0000001:
		return 0.0
	return atan2(-right_velocity, forward_velocity)


func calculate_slip_ratio(forward_velocity: float) -> float:
	var tyre_velocity := angular_velocity * radius
	var ratio := (tyre_velocity - forward_velocity) / maxf(1.0, maxf(absf(forward_velocity), absf(tyre_velocity)))
	return ratio
