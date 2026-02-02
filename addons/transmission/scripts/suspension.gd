extends RefCounted
class_name Suspension

var compress: float
var contact: bool

var _stiffness: float
var _damping_compress: float
var _damping_relax: float
var _length: float
var _mass: float
var _spring_velocity: float
var _simple: bool


func _init(stiffness: float, damping_compress: float, damping_relax: float, length: float, mass: float, simple: bool) -> void:
	_stiffness = stiffness
	_damping_compress = damping_compress
	_damping_relax = damping_relax
	_length = length
	_mass = mass
	_simple = simple


func calculate_force(delta: float, collision_compress: float, stabilizer_force: float) -> float:
	if _simple:
		return _calculate_simple(delta, collision_compress, stabilizer_force)
	return _calculate_force(delta, collision_compress, stabilizer_force)


func _calculate_simple(delta: float, collision_compress: float, stabilizer_force: float) -> float:
	contact = collision_compress > 0.0
	if contact:
		_spring_velocity = clampf((collision_compress - compress) / delta, -10.0, 10.0)
		compress = collision_compress
		var damping := _damping_compress if _spring_velocity > 0.0 else _damping_relax
		var force := -stabilizer_force - compress * _stiffness - _spring_velocity * damping
		return maxf(0.0, -force)
	compress = lerpf(compress, 0, delta)
	_spring_velocity = 0.0
	return 0.0


func _calculate_force(delta: float, collision_compress: float, stabilizer_force: float) -> float:
	contact = collision_compress >= compress
	if contact:
		_spring_velocity = clampf((collision_compress - compress) / delta, -10.0, 10.0)
		compress = collision_compress
	var damping := _damping_compress if _spring_velocity > 0.0 else _damping_relax
	var force := -stabilizer_force - compress * _stiffness - _spring_velocity * damping
	_spring_velocity += force * delta / _mass
	compress += _spring_velocity * delta
	contact = collision_compress >= compress
	return -force
