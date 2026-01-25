extends Node
class_name AirDrag

@export var density := 1.2255
@export var area := 2.25
@export var drag_factor := 0.29

@onready var _body := get_parent() as RigidBody3D


func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var velocity := _body.linear_velocity
	var force := -velocity * velocity.length() * drag_factor * area * density * 0.5
	_body.apply_central_force(force)
