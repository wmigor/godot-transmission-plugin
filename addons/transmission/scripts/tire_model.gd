@tool
extends Resource
class_name TireModel

## D
@export var peak := 1.2:
	set(value):
		peak = value
		emit_changed()
## B
@export var stiffness := 12.5:
	set(value):
		stiffness = value
		emit_changed()
## C
@export var shape := 1.75:
	set(value):
		shape = value
		emit_changed()
## E
@export var curvature := 0.85:
	set(value):
		curvature = value
		emit_changed()


func get_value(slip: float) -> float:
	var stiffness_slip := stiffness * slip
	var value := peak * sin(shape * atan(stiffness_slip - curvature * (stiffness_slip - atan(stiffness_slip))))
	return value
