extends RayCast3D
class_name Wheel

@export_category("Wheel")
@export var steer_angle_max := 0.0
@export var hand_brakable: bool
@export var radius := 0.316
@export var inertia := 1.2
@export var tire_model_longitudinal: TireModel
@export var tire_model_lateral: TireModel
@export var max_brake_torque := 2000.0

@export_category("Spring")
@export var spring_stiffness := 20000.0
@export var spring_damping_compress := 0.5
@export var spring_damping_relax := 0.5
@export var spring_length := 0.5
@export var spring_simple := true
@export var spring_mass := 50.0

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


func _ready() -> void:
	var body := _get_parent_body()
	var wheel_count := len(body.find_children("*", "Wheel"))
	suspension = Suspension.new(spring_stiffness, spring_damping_compress, spring_damping_relax, spring_length, spring_mass, body.mass / wheel_count, spring_simple)
	add_exception(body)
	target_position = Vector3.DOWN * (radius + spring_length)
	position += Vector3.UP * spring_length


func _get_parent_body() -> RigidBody3D:
	var parent = get_parent()
	while parent != null:
		if parent is RigidBody3D:
			return parent
		parent = parent.get_parent()
	return null


func _get_spring_direction() -> Vector3:
	var vector := global_position - to_global(target_position)
	vector = vector.normalized()
	return vector


func get_contact_point() -> Vector3:
	if is_colliding():
		return get_collision_point()
	return to_global(target_position) + _get_spring_direction() * radius


func calculate_force(delta: float, body: RigidBody3D, center_of_mass: Vector3) -> void:
	var spring_direction := _get_spring_direction()
	var normal := get_collision_normal() if is_colliding() else spring_direction
	var right := global_basis.x
	var forward := normal.cross(right)
	var force_spring_to_tire := _calculate_spring_force(delta, spring_direction, body, center_of_mass)
	var tire_arm := get_contact_point() - center_of_mass
	var tire_velocity := body.linear_velocity + body.angular_velocity.cross(tire_arm)
	var tire_force := _calculate_tire_force(tire_velocity, force_spring_to_tire, forward)
	_tire_torque = -tire_force.dot(forward) * radius
	shaft.torque = _tire_torque
	body.apply_force(tire_force, tire_arm)
	update_shafts()


func update_shafts() -> void:
	shaft.inertia = inertia
	shaft.brake_torque = brake_torque
	shaft.angular_velocity = angular_velocity


func _calculate_tire_force(velocity: Vector3, spring_force: float, forward: Vector3) -> Vector3:
	var right := global_basis.x
	_forward_velocity = velocity.dot(forward)
	var right_velocity := velocity.dot(right)
	var slip_angle := calculate_slip_angle(_forward_velocity, right_velocity)
	var slip_ratio := calculate_slip_ratio(_forward_velocity)

	var f := _get_tire_forces(slip_angle, slip_ratio, spring_force) if spring_force > 0.0 else Vector2.ZERO
	if absf(_forward_velocity + angular_velocity * radius) < TAU * radius:
		skid_factor = 0.0
	else:
		skid_factor = clamp(sqrt(sin(slip_angle) ** 2 + slip_ratio ** 2), 0.0, 1.0) if spring_force > 0.0 else 0.0
	if spring_force <= 0.0:
		_last_forward_force = 0.0
		_last_right_force = 0.0
	var forward_force := _last_forward_force + 0.5 * (f.x - _last_forward_force)
	var right_force := _last_right_force + 0.5 * (f.y - _last_right_force)
	_last_forward_force = forward_force
	_last_right_force = right_force
	return forward_force * forward + right_force * right


func _get_tire_forces(slip_angle: float, slip_ratio: float, weight: float) -> Vector2:
	if tire_model_longitudinal == null or tire_model_lateral == null:
		return Vector2.ZERO
	var ground_friction := _get_ground_friction()
	var fx := tire_model_longitudinal.get_value(slip_ratio) * weight * ground_friction
	var fy := tire_model_lateral.get_value(slip_angle) * weight* ground_friction
	var fx_max := tire_model_longitudinal.peak * weight* ground_friction
	var fy_max := tire_model_lateral.peak * weight* ground_friction
	var elliptic_value := fx * fx / (fx_max * fx_max) + fy * fy / (fy_max * fy_max)
	if elliptic_value > 1.0:
		return Vector2(fx, fy) / sqrt(elliptic_value)
	return Vector2(fx, fy)


func apply_torque(delta: float) -> void:
	angular_velocity += delta * (shaft.torque + _tire_torque) / inertia
	update_shafts()


func update_rotation(delta: float, free: bool, brake: float) -> void:
	brake_torque = -signf(angular_velocity) * brake * max_brake_torque
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
			var direction := target_position.normalized()
			child.position = (target_position - radius * direction).lerp(Vector3.ZERO, suspension.compress / spring_length)
			child.rotate_x(-angular_velocity * delta)


func _calculate_spring_force(delta: float, spring_direction: Vector3, body: RigidBody3D, center_of_mass: Vector3) -> float:
	var collision_compress := _get_collision_compress(spring_direction)
	var force := suspension.calculate_force(delta, collision_compress, stabilizer_force)
	var spring_arm := global_position - center_of_mass
	body.apply_force(force * spring_direction, spring_arm)
	if not suspension.contact:
		return 0.0
	return maxf(0.0, force)


func _get_collision_compress(spring_direction: Vector3) -> float:
	if not is_colliding():
		return 0.0
	var vector := get_collision_point() - global_position
	return maxf(0.0, spring_length + radius + vector.dot(spring_direction))


func _get_ground_friction() -> float:
	if not is_colliding():
		return 0.0
	var ground := get_collider() as StaticBody3D
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
