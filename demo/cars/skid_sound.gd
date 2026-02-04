extends AudioStreamPlayer3D

@export_range(0.0, 1.0, 0.01) var min_skid_factor := 0.1

@onready var _body := get_parent() as RigidBody3D

var _wheels: Array[Wheel]


func _ready() -> void:
	if _body != null:
		_wheels.append_array(_body.find_children("*", "Wheel"))


func _process(_delta: float) -> void:
	if _body == null:
		return
	var skid_volume := _get_skid_sound_volume()
	if skid_volume > 0.0:
		if !playing:
			play()
		volume_linear = skid_volume
	elif skid_volume <= 0.0 and playing:
		stop()


func _get_skid_sound_volume() -> float:
	if _body == null:
		return 0.0
	var max_factor = 0.0
	for wheel in _wheels:
		if wheel.skid_factor > max_factor:
			max_factor = wheel.skid_factor
	if max_factor < min_skid_factor:
		return 0.0
	return (max_factor - min_skid_factor) / (1.0 - min_skid_factor)
	
