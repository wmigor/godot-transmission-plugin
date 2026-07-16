extends Constraint
class_name GearConstraint

var shaft1: Shaft
var shaft2: Shaft
var gear_ratio: float

var effective_mass: float
var accumulated_impulse: float

var sliding: bool


func _init(shaft1_: Shaft, shaft2_: Shaft, gear_ratio_: float):
	shaft1 = shaft1_
	shaft2 = shaft2_
	gear_ratio = gear_ratio_


func shift_gear(new_ratio: float):
	gear_ratio = new_ratio
	accumulated_impulse = 0.0


func pre_step(_delta: float) -> void:
	if gear_ratio == 0.0:
		effective_mass = 0.0
		accumulated_impulse = 0.0
		return

	var K := shaft1.inv_inertia + gear_ratio * gear_ratio * shaft2.inv_inertia
	effective_mass = 1.0 / K
	
	shaft1.apply_torque_impulse(accumulated_impulse)
	shaft2.apply_torque_impulse(-gear_ratio * accumulated_impulse)


func step(_delta: float) -> void:
	if gear_ratio == 0.0:
		return

	var jv: float = shaft1.angular_velocity - gear_ratio * shaft2.angular_velocity
	var lambda: float = -jv * effective_mass
	accumulated_impulse += lambda
	shaft1.apply_torque_impulse(lambda)
	shaft2.apply_torque_impulse(-gear_ratio * lambda)
