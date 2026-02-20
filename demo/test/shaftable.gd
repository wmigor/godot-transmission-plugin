@tool
@abstract
extends Node2D
class_name Shaftable

@onready var input_shaft := get_parent() as ShaftView


@abstract
func update_feedback() -> void

@abstract
func update(delta: float) -> void
