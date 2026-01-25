extends AudioStreamPlayer3D

@export var _motor_path: NodePath
@export var _min_pitch := 0.15

@onready var _motor := get_node(_motor_path) as Motor


func _process(_delta: float) -> void:
	if _motor != null:
		var t := _motor.rpm / (_motor.max_rpm - _motor.idle_rpm)
		pitch_scale = maxf(_min_pitch, lerpf(_min_pitch, 1, t))
		volume_db = lerpf(-20.0, 0.0, t)
		if not playing:
			play()
