extends Node

@export var transmission_path: NodePath

@onready var transmission := get_node(transmission_path) as Transmission
@onready var vehicle := get_parent() as VehicleBody3D

var _steering_key := 0.0
var _brake_key := 0.0


func _physics_process(delta: float) -> void:
	var target_steering_key := Input.get_axis("ui_right", "ui_left")
	_steering_key = move_toward(_steering_key, target_steering_key, delta * 2.0)
	_brake_key = move_toward(_brake_key, Input.get_action_strength("brake"), delta)
	if transmission != null:
		transmission.input_steering = clampf(_steering_key + Input.get_axis("steering_right", "steering_left"), -1.0, 1.0)
		transmission.motor.input_throttle = Input.get_action_strength("throttle")
		transmission.input_brake = _brake_key
		if Input.is_action_just_pressed("gear_up"):
			transmission.gear_box.gear_up()
		if Input.is_action_just_pressed("gear_down"):
			transmission.gear_box.gear_down()
		transmission.clutch.input_value = 1.0 - Input.get_action_strength("clutch")
