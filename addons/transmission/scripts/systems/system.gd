@abstract
extends Node
class_name System

signal enable_changed(bool)
signal indicator_changed(bool)

@export var enabled := true:
	set(value):
		if enabled != value:
			enabled = value
			_on_enable_changed()
			enable_changed.emit(enabled)
			indicator = false

var indicator: bool:
	set(value):
		if indicator != value:
			indicator = value
			indicator_changed.emit(indicator)


@abstract
func update(delta: float) -> void


func _on_enable_changed() -> void:
	pass
