extends Node

@export var transmission_path: NodePath
@export var clutch_on_hand_brake := true

@onready var transmission := get_node(transmission_path) as Transmission
@onready var vehicle := get_parent() as VehicleBody3D

var _steering_key := 0.0
var _brake_key := 0.0
var _throttle_key := 0.0
var _clutch_key := 0.0
var _mouse_control: bool
var clutch_mode := true


func _physics_process(delta: float) -> void:
	var target_steering_key := Input.get_axis("steering_right_key", "steering_left_key")
	_steering_key = move_toward(_steering_key, target_steering_key, delta * 2.0)
	_brake_key = move_toward(_brake_key, Input.get_action_strength("brake_key"), delta * 2.0)
	_throttle_key = move_toward(_throttle_key, maxf(Input.get_action_strength("throttle_key"), Input.get_action_strength("reverse_key")), delta * 5.0)
	_clutch_key = move_toward(_clutch_key, Input.get_action_strength("clutch_key"), delta * 2)
	if transmission != null:
		transmission.input_steering = clampf(_steering_key + Input.get_axis("steering_right", "steering_left"), -1.0, 1.0)
		transmission.motor.input_throttle = clampf(Input.get_action_strength("throttle") + _throttle_key, 0.0, 1.0)
		transmission.input_hand_brake = Input.get_action_strength("hand_brake")
		var brake_input := Input.get_action_strength("clutch") if not clutch_mode else 0.0
		transmission.input_brake = clampf(brake_input + _brake_key, 0.0, 1.0)
		var clutch_input := Input.get_action_strength("clutch") if clutch_mode else 0.0
		transmission.clutch.input_value = 1.0 - clampf(clutch_input + _clutch_key, 0.0, 1.0)
		if clutch_on_hand_brake and transmission.input_hand_brake > 0.0 or transmission.motor.rpm <= transmission.motor.torque_curve.idle_rpm:
			transmission.clutch.input_value = 0.0
		_process_mouse_control()


func _process_mouse_control() -> void:
	if not _mouse_control:
		return
	var viewport := get_viewport()
	var width := viewport.get_visible_rect().size.x
	var x := get_viewport().get_mouse_position().x
	transmission.input_steering = clampf(2.0 * (width / 2.0 - x) / width, -1.0, 1.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gear_up"):
		transmission.gear_box.gear_up()
	if event.is_action_pressed("gear_down"):
		transmission.gear_box.gear_down()
	if event.is_action_pressed("mode"):
		clutch_mode = not clutch_mode
	if event.is_action_pressed("switch_differential"):
		transmission.differential.switch()
	if event.is_action_pressed("toggle_tcs"):
		var tcs := transmission.get_system("Tcs")
		if tcs != null:
			tcs.enabled = not tcs.enabled
	if event is InputEventMouseMotion:
		_mouse_control = true
	elif event.is_action("steering_left_key") or event.is_action("steering_right_key"):
		_mouse_control = false
		_steering_key = transmission.input_steering
	elif event.is_action("steering_left") or event.is_action("steering_right"):
		_mouse_control = false
	if transmission.gear_box.gear > 0.0 and event.is_action_pressed("reverse_key"):
		transmission.gear_box.set_reverse_gear()
	if transmission.gear_box.gear < 0.0 and event.is_action_pressed("throttle_key"):
		transmission.gear_box.gear_up()
