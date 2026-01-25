extends Node

@export var transmission_path: NodePath
@export var brake := 50.0

@onready var transmission := get_node(transmission_path) as Transmission
@onready var vehicle := get_parent() as VehicleBody3D

var _steering_key := 0.0
var _brake_press := 0.0


func _physics_process(delta: float) -> void:
	if vehicle != null:
		var target_steering_key := Input.get_axis("ui_right", "ui_left")
		_steering_key = move_toward(_steering_key, target_steering_key, delta)
		vehicle.steering = deg_to_rad(45.0) * clampf(_steering_key + Input.get_axis("steering_right", "steering_left"), -1.0, 1.0)
		_brake_press = move_toward(_brake_press, Input.get_action_strength("brake"), delta)
		vehicle.brake = brake * _brake_press
	if transmission != null:
		transmission.motor.input_throttle = Input.get_action_strength("throttle")
		if Input.is_action_just_pressed("gear_up"):
			transmission.gear_box.gear_up()
		if Input.is_action_just_pressed("gear_down"):
			transmission.gear_box.gear_down()
		transmission.clutch.input_value = 1.0 - Input.get_action_strength("clutch")
