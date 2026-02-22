@tool
extends Shaftable
class_name DifferentialView

@onready var output_shaft1 := get_child(0) as ShaftView
@onready var output_shaft2 := get_child(1) as ShaftView


func update_feedback() -> void:
	output_shaft1.update_feedback()
	output_shaft2.update_feedback()
	input_shaft.angular_velocity = 0.5 * (output_shaft1.angular_velocity + output_shaft2.angular_velocity)
	var w1 := (output_shaft1.angular_velocity / input_shaft.angular_velocity) if absf(input_shaft.angular_velocity) > 0.0 else 1.0
	var w2 := (output_shaft2.angular_velocity / input_shaft.angular_velocity) if absf(input_shaft.angular_velocity) > 0.0 else 1.0
	input_shaft.torque = 0.5 * (output_shaft1.torque + output_shaft2.torque)
	input_shaft.total_inertia = input_shaft.inertia + output_shaft1.total_inertia * w1 * w1 + output_shaft2.total_inertia * w2 * w2
	input_shaft.raw_inertia = input_shaft.inertia + output_shaft1.raw_inertia + output_shaft2.raw_inertia
	#print(name, ' ', w1, ' ', w2, '   ', input_shaft.total_inertia, '   ', input_shaft.raw_inertia)


func update(delta: float) -> void:
	var delta_torque := output_shaft1.torque - output_shaft2.torque
	var m := input_shaft.raw_inertia / input_shaft.total_inertia
	output_shaft1.torque = input_shaft.torque * 0.5 * m + delta_torque
	output_shaft2.torque = input_shaft.torque * 0.5 * m - delta_torque
	output_shaft1.update(delta)
	output_shaft2.update(delta)
