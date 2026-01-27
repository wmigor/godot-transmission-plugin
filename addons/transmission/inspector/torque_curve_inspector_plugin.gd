@tool
extends EditorInspectorPlugin

var TorqueCurveView := preload("uid://c37ry7157t5em")


func _can_handle(object: Object) -> bool:
	return object is TorqueCurve


func _parse_begin(object: Object) -> void:
	var curve := object as TorqueCurve
	if curve == null:
		return
	var view := TorqueCurveView.new()
	view.curve = curve
	view.custom_minimum_size.y = 384
	add_custom_control(view)
