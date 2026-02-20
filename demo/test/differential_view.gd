@tool
extends Shaftable
class_name DifferentialView

@onready var output_shaft1 := get_child(0) as ShaftView
@onready var output_shaft2 := get_child(1) as ShaftView


func update_feedback() -> void:
	output_shaft1.update_feedback()
	output_shaft2.update_feedback()
	input_shaft.angular_velocity = 0.5 * (output_shaft1.angular_velocity + output_shaft2.angular_velocity)
	input_shaft.torque = 0.5 * (output_shaft1.torque + output_shaft2.torque)
	input_shaft.total_inertia = input_shaft.inertia + output_shaft1.total_inertia + output_shaft2.total_inertia


func update(delta: float) -> void:
	var delta_torque := output_shaft1.torque - output_shaft2.torque
	output_shaft1.torque = input_shaft.torque * 0.5 + delta_torque
	output_shaft2.torque = input_shaft.torque * 0.5 - delta_torque
	output_shaft1.update(delta)
	output_shaft2.update(delta)
