extends Constraint
class_name DifferencialConstraint

var shaft_in: Shaft
var shaft1: Shaft
var shaft2: Shaft

const j_in := 1.0
const j_out = -0.5

var effective_mass: float
var accumulated_impulse: float

var sliding: bool


func _init(shaft_in_: Shaft, shaft1_: Shaft, shaft2_: Shaft):
	shaft_in = shaft_in_
	shaft1 = shaft1_
	shaft2 = shaft2_


func pre_step(_delta: float) -> void:
	var k := j_in * j_in * shaft_in.inv_inertia + j_out * j_out * (shaft1.inv_inertia + shaft2.inv_inertia)
	effective_mass = 1.0 / k

	shaft_in.apply_torque_impulse(j_in * accumulated_impulse)
	shaft1.apply_torque_impulse(j_out * accumulated_impulse)
	shaft2.apply_torque_impulse(j_out * accumulated_impulse)


func step(_delta: float) -> void:
	var jv: float = j_in * shaft_in.angular_velocity + j_out * (shaft1.angular_velocity + shaft2.angular_velocity)
	var lambda: float = -jv * effective_mass
	
	accumulated_impulse += lambda

	shaft_in.apply_torque_impulse(j_in * lambda)
	shaft1.apply_torque_impulse(j_out * lambda)
	shaft2.apply_torque_impulse(j_out * lambda)
