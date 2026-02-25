extends Node3D
class_name Wheel

@export_category("Wheel")
@export var steer_angle_max := 0.0
@export var hand_brakable: bool
@export var radius := 0.316
@export var inertia := 1.2
@export var tire_model_longitudinal: TireModel
@export var tire_model_lateral: TireModel
@export var max_brake_torque := 2000.0
@export var relaxation_length := 0.2
@export_range(0.0, 1.0, 0.001) var relaxation_damping := 1.0

@export_category("Spring")
@export var spring_stiffness := 20000.0
@export var spring_damping_compress := 4000.0
@export var spring_damping_relax := 4000.0
@export var spring_length := 0.5
@export var spring_simple := true
@export var spring_mass := 50.0

@onready var _ray_cast := RayCast3D.new()

var shaft := Shaft.new()
var angular_velocity: float
var brake_torque: float
var skid_factor: float
var _tire_torque: float
var _last_forward_force: float
var _last_right_force: float
var _forward_velocity: float
var _old_av: float
var suspension: Suspension
var stabilizer_force: float
var deflection: Vector2
var deflection_limit: Vector2


var use_relaxation: bool:
	get(): return relaxation_length > 0.0


func _ready() -> void:
	suspension = Suspension.new(spring_stiffness, spring_damping_compress, spring_damping_relax, spring_length, spring_mass, spring_simple)
	var body := _get_parent_body()
	_ray_cast.add_exception(body)
	_ray_cast.position = body.to_local(global_position) + Vector3.UP * spring_length
	_ray_cast.target_position = Vector3.DOWN * (radius + spring_length)
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


func calculate_force(delta: float, body: RigidBody3D, center_of_mass: Vector3) -> void:
	var spring_direction := _get_spring_direction()
	var normal := _ray_cast.get_collision_normal() if _ray_cast.is_colliding() else spring_direction
	var right := global_basis.x
	var forward := normal.cross(right)
	var force_spring_to_tire := _calculate_spring_force(delta, spring_direction, body, center_of_mass)
	var tire_arm := get_contact_point() - center_of_mass
	var tire_velocity := body.linear_velocity + body.angular_velocity.cross(tire_arm)
	var tire_force := _calculate_tire_force(tire_velocity, force_spring_to_tire, forward, delta)
	_tire_torque = -tire_force.dot(forward) * radius
	shaft.torque = _tire_torque
	body.apply_force(tire_force, tire_arm)
	update_shafts()


func update_shafts() -> void:
	shaft.inertia = inertia
	shaft.brake_torque = brake_torque
	shaft.angular_velocity = angular_velocity


func _calculate_tire_force(velocity: Vector3, spring_force: float, forward: Vector3, delta: float) -> Vector3:
	var right := global_basis.x
	_forward_velocity = velocity.dot(forward)
	var right_velocity := velocity.dot(right)
	var slip_angle: float
	var slip_ratio: float
	var damping: Vector2
	if use_relaxation:
		var old_deflection := deflection
		_update_deflection(right_velocity, spring_force, delta)
		damping = maxf(0.0, spring_force) * relaxation_damping * (old_deflection - deflection) / delta
		slip_ratio = (deflection.x / deflection_limit.x) if deflection_limit.x > 0.0 else 0.0
		slip_angle = atan(deflection.y / deflection_limit.y) if deflection_limit.y > 0.0 else 0.0
	else:
		slip_angle = calculate_slip_angle(_forward_velocity, right_velocity)
		slip_ratio = calculate_slip_ratio(_forward_velocity)

	var f := _get_tire_forces(slip_angle, slip_ratio, spring_force) if spring_force > 0.0 else Vector2.ZERO
	if absf(_forward_velocity + angular_velocity * radius) < TAU * radius:
		skid_factor = 0.0
	else:
		skid_factor = clamp(sqrt(sin(slip_angle) ** 2 + slip_ratio ** 2), 0.0, 1.0) if spring_force > 0.0 else 0.0

	if use_relaxation:
		return (f.x - damping.x) * forward + (f.y - damping.y) * right

	if spring_force <= 0.0:
		_last_forward_force = 0.0
		_last_right_force = 0.0
	var forward_force := _last_forward_force + 0.5 * (f.x - _last_forward_force)
	var right_force := _last_right_force + 0.5 * (f.y - _last_right_force)
	_last_forward_force = forward_force
	_last_right_force = right_force
	return forward_force * forward + right_force * right


func _update_deflection(right_velocity: float, spring_force: float, delta: float) -> void:
	var v_relative := Vector2(angular_velocity * radius - _forward_velocity, -right_velocity)
	var v_rolling := absf(angular_velocity * radius)
	var relaxation := v_rolling / relaxation_length
	var deflection_deriv := v_relative - relaxation * deflection
	var old_deflection := deflection
	deflection += deflection_deriv * delta
	deflection = old_deflection + 0.5 * (deflection - old_deflection)
	var max_force := _get_ground_friction() * spring_force * Vector2(tire_model_longitudinal.peak, tire_model_lateral.peak)
	var stiffness := Vector2(tire_model_longitudinal.get_stiffnes_base(), tire_model_lateral.get_stiffnes_base()) * spring_force
	deflection_limit.x = maxf(0.0, max_force.x / maxf(stiffness.x, 1.0))
	deflection_limit.y = maxf(0.0, max_force.y / maxf(stiffness.y, 1.0))
	deflection.x = clampf(deflection.x, -deflection_limit.x, deflection_limit.x)
	deflection.y = clampf(deflection.y, -deflection_limit.y, deflection_limit.y)


func _get_tire_forces(slip_angle: float, slip_ratio: float, weight: float) -> Vector2:
	if tire_model_longitudinal == null or tire_model_lateral == null:
		return Vector2.ZERO
	var ground_friction := _get_ground_friction()
	var fx := tire_model_longitudinal.get_value(slip_ratio) * weight * ground_friction
	var fy := tire_model_lateral.get_value(slip_angle) * weight* ground_friction
	var fx_max := tire_model_longitudinal.peak * weight * ground_friction
	var fy_max := tire_model_lateral.peak * weight * ground_friction
	var elliptic_value := fx * fx / (fx_max * fx_max) + fy * fy / (fy_max * fy_max)
	if elliptic_value > 1.0:
		return Vector2(fx, fy) / sqrt(elliptic_value)
	return Vector2(fx, fy)


func apply_torque(delta: float) -> void:
	angular_velocity += delta * (shaft.torque + _tire_torque) / inertia
	update_shafts()


func update_rotation(delta: float, free: bool, brake: float) -> void:
	brake_torque = -signf(angular_velocity) * brake * max_brake_torque
	if not use_relaxation:
		if free and absf(brake_torque) > 0.0:
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
	update_shafts()

	for i in get_child_count():
		var child := get_child(i) as Node3D
		if child != null:
			child.position.x = deflection.y
			child.position.z = -deflection.x
			child.rotate_x(-angular_velocity * delta)


func _calculate_spring_force(delta: float, spring_direction: Vector3, body: RigidBody3D, center_of_mass: Vector3) -> float:
	var collision_compress := _get_collision_compress(spring_direction)
	var force := suspension.calculate_force(delta, collision_compress, stabilizer_force)
	var spring_arm := _ray_cast.global_position - center_of_mass
	body.apply_force(force * spring_direction, spring_arm)
	global_position = _ray_cast.global_position - spring_direction * (spring_length - suspension.compress)
	if not suspension.contact:
		return 0.0
	return maxf(0.0, force)


func _get_collision_compress(spring_direction: Vector3) -> float:
	if not _ray_cast.is_colliding():
		return 0.0
	var vector := _ray_cast.get_collision_point() - _ray_cast.global_position
	return maxf(0.0, spring_length + radius + vector.dot(spring_direction))


func _get_ground_friction() -> float:
	if not _ray_cast.is_colliding():
		return 0.0
	var ground := _ray_cast.get_collider() as StaticBody3D
	if ground == null or ground.physics_material_override == null:
		return 1.0
	return ground.physics_material_override.friction
	

static func calculate_slip_angle(forward_velocity: float, right_velocity: float) -> float:
	if absf(forward_velocity) < 0.0000001 and absf(right_velocity) < 0.0000001:
		return 0.0
	return atan2(-right_velocity, forward_velocity)


func calculate_slip_ratio(forward_velocity: float) -> float:
	var tire_velocity := angular_velocity * radius
	var ratio := (tire_velocity - forward_velocity) / maxf(1.0, maxf(absf(forward_velocity), absf(tire_velocity)))
	return ratio
