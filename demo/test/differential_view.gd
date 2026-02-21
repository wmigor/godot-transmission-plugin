@tool
extends Shaftable
class_name DifferentialView

@onready var output_shaft1 := get_child(0) as ShaftView
@onready var output_shaft2 := get_child(1) as ShaftView


func update_feedback() -> void:
	output_shaft1.update_feedback()
	output_shaft2.update_feedback()


func update(delta: float) -> void:
	output_shaft1.update(delta)
	output_shaft2.update(delta)
	var r1 := -2.0
	var r2 := 1.0
	var r3 := 1.0
	var error := r1 * input_shaft.angular_velocity + r2 * output_shaft1.angular_velocity + r3 * output_shaft2.angular_velocity
	var inv_intertia := r1 * r1 / input_shaft.inertia + r2 * r2 / output_shaft1.inertia + r3 * r3 / output_shaft2.inertia
	var p := -error / inv_intertia
	input_shaft.angular_velocity += r1 * p / input_shaft.inertia
	output_shaft1.angular_velocity += r2 * p / output_shaft1.inertia
	output_shaft2.angular_velocity += r2 * p / output_shaft2.inertia
	#print(input_shaft.angular_velocity, '  ', 0.5 * (output_shaft1.angular_velocity + output_shaft2.angular_velocity))
