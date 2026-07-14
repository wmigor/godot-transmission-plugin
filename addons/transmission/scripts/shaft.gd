extends RefCounted
class_name Shaft

var angular_velocity: float
var torque: float
var brake_torque: float
var angle: float

var inertia := 1.0:
	get(): return inertia
	set(value):
		inertia = value
		inv_inertia = (1.0 / inertia) if inertia > 0.0 else 0.0

var inv_inertia := 1.0:
	get(): return inv_inertia


func _init(inertia_ := 1.0):
	inertia = inertia_
	inv_inertia = (1.0 / inertia) if inertia > 0.0 else 0.0


func apply_torque_impulse(impulse: float) -> void:
	angular_velocity += impulse * inv_inertia


func integrate_angular_velocity(delta: float) -> void:
	angular_velocity += torque * delta * inv_inertia
	torque = 0.0


func integrate_angle(delta: float) -> void:
	angle += angular_velocity * delta
