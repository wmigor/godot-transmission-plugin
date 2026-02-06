@tool
extends Node
class_name TransmissionComponent

var transmission: Transmission:
	get(): return transmission


func _enter_tree() -> void:
	transmission = get_parent() as Transmission


func _exit_tree() -> void:
	transmission = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if transmission == null:
		warnings.append("Please only use it as a child of Transmission")
	return warnings
