extends RefCounted
class_name Solver

var shafts: Array[Shaft]
var constraints: Array[Constraint]


func step(delta: float) -> void:
	for shaft in shafts:
		shaft.integrate_angular_velocity(delta)
	for constraint in constraints:
		constraint.pre_step()
	for i in 20:
		for constraint in constraints:
			constraint.step(delta)
	for shaft in shafts:
		shaft.integrate_angle(delta)
