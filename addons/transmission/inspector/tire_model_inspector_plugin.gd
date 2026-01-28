@tool
extends EditorInspectorPlugin

var TireModelView := preload("uid://dat2pujqaq0p0")


func _can_handle(object: Object) -> bool:
	return object is TireModel


func _parse_begin(object: Object) -> void:
	var tire_model := object as TireModel
	if tire_model == null:
		return
	var view := TireModelView.new()
	view.tire_model = tire_model
	view.custom_minimum_size.y = 384
	add_custom_control(view)
