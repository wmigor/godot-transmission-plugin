extends Constraint
class_name BrakeConstraint

var shaft: Shaft
var radius: float
var friction_factor: float
var max_normal_force: float
var pedal: float

var effective_mass: float
var accumulated_impulse: float

var sliding: bool


func _init(shaft_: Shaft, radius_: float, friction_factor_: float, max_normal_force_: float):
	shaft = shaft_
	radius = radius_
	friction_factor = friction_factor_
	max_normal_force = max_normal_force_


func pre_step(_delta: float) -> void:
	effective_mass = 1.0 / shaft.inv_inertia
	shaft.apply_torque_impulse(accumulated_impulse)


func step(delta: float) -> void:
	var lambda := -shaft.angular_velocity * effective_mass
	var max_torque := friction_factor * max_normal_force * radius * pedal
	var max_impulse := max_torque * delta
	
	var old_accumulated = accumulated_impulse
	var new_accumulated := accumulated_impulse + lambda
	sliding = new_accumulated > max_impulse or new_accumulated < -max_impulse
	accumulated_impulse = clampf(new_accumulated, -max_impulse, max_impulse)
	lambda = accumulated_impulse - old_accumulated
	
	shaft.apply_torque_impulse(lambda)
