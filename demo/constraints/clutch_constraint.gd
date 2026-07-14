extends Constraint
class_name ClutchConstraint

var shaft1: Shaft
var shaft2: Shaft

var max_torque: float
var clutch_pedal: float

var effective_mass: float
var accumulated_impulse: float

var sliding: bool


func _init(shaft1_: Shaft, shaft2_: Shaft, max_torque_: float):
	shaft1 = shaft1_
	shaft2 = shaft2_
	max_torque = max_torque_


func pre_step() -> void:
	var k := shaft1.inv_inertia + shaft2.inv_inertia
	effective_mass = 1.0 / k

	shaft1.apply_torque_impulse(1.0 * accumulated_impulse)
	shaft2.apply_torque_impulse(-1.0 * accumulated_impulse)


func step(delta: float) -> void:
	var jv: float = shaft1.angular_velocity - shaft2.angular_velocity
	var lambda: float = -jv * effective_mass
	
	var current_max_clutch_torque = max_torque * (1.0 - clutch_pedal)
	var max_impulse: float = current_max_clutch_torque * delta

	var old_accumulated = accumulated_impulse
	var new_accumulated := accumulated_impulse + lambda
	sliding = new_accumulated > max_impulse or new_accumulated < -max_impulse
	accumulated_impulse = clampf(new_accumulated, -max_impulse, max_impulse)
	lambda = accumulated_impulse - old_accumulated

	shaft1.apply_torque_impulse(lambda)
	shaft2.apply_torque_impulse(-lambda)
