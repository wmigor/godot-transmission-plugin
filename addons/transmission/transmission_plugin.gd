@tool
extends EditorPlugin

var TorqueCurveInspectorPlugin = preload("uid://bqiabq6iy6xq0")
var TireModelInspectorPlugin = preload("uid://brqcltjp8t1im")

var _torque_curve_inspector: EditorInspectorPlugin
var _tire_model_inspector: EditorInspectorPlugin


func _enter_tree() -> void:
	_torque_curve_inspector = TorqueCurveInspectorPlugin.new()
	add_inspector_plugin(_torque_curve_inspector)
	_tire_model_inspector = TireModelInspectorPlugin.new()
	add_inspector_plugin(_tire_model_inspector)
	


func _exit_tree() -> void:
	remove_inspector_plugin(_torque_curve_inspector)
	_torque_curve_inspector = null
	remove_inspector_plugin(_tire_model_inspector)
	_tire_model_inspector = null
