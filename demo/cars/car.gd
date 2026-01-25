extends VehicleBody3D
class_name Car

@onready var transmission := $Transmission as Transmission

var _steering_key := 0.0

func _physics_process(delta: float) -> void:
	var target_steering_key := Input.get_axis("ui_right", "ui_left")
	_steering_key = move_toward(_steering_key, target_steering_key, delta)
	steering = deg_to_rad(45.0) * clampf(_steering_key + Input.get_axis("steering_right", "steering_left"), -1.0, 1.0)
	transmission.input_throttle = Input.get_action_strength("throttle")
	if Input.is_action_just_pressed("gear_up"):
		transmission.gear_box.gear_up()
		transmission.clutch.clutch_locked = false
	if Input.is_action_just_pressed("gear_down"):
		transmission.gear_box.gear_down()
		transmission.clutch.clutch_locked = false
