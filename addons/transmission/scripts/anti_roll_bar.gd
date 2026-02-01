extends Node
class_name AntiRollBar

@export var wheel1_path: NodePath
@export var wheel2_path: NodePath
@export var stiffness := 10000.0

@onready var wheel1 := get_node(wheel1_path) as Wheel
@onready var wheel2 := get_node(wheel2_path) as Wheel


func update_forces() -> void:
	if wheel1 == null or wheel2 == null:
		return
	var compress1 := wheel1.suspension.compress - wheel1.spring_length
	var compress2 := wheel2.suspension.compress - wheel2.spring_length
	var force := stiffness * (compress2 - compress1)
	wheel1.stabilizer_force = -force
	wheel2.stabilizer_force = force
