@tool
extends EditorPlugin

var X = preload("uid://bqiabq6iy6xq0")

var _x: EditorInspectorPlugin


func _enter_tree() -> void:
	_x = X.new()
	add_inspector_plugin(_x)
	


func _exit_tree() -> void:
	remove_inspector_plugin(_x)
	_x = null
