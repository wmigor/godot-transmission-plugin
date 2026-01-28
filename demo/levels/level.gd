extends Node3D

@export var car_scenes: Array[PackedScene]

@onready var _hud := $Hud as Hud

var _car_index := 0
var _car: Car


func _ready() -> void:
	_spawn_car(_car_index)


func _spawn_car(index: int) -> void:
	_clear()
	_car_index = index
	if index < 0 or index >= len(car_scenes) or car_scenes[index] == null:
		return
	_car = car_scenes[index].instantiate() as Car
	if _car == null:
		return
	_car.position.y = 1.0
	add_child(_car, true)
	if _hud != null:
		_hud.car = _car


func _clear() -> void:
	if _hud != null:
		_hud.car = null
	if _car != null:
		_car.queue_free()
		_car = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_next"):
		_spawn_next()
	elif event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()


func _spawn_next() -> void:
	if len(car_scenes) > 0:
		_spawn_car((_car_index + 1) % len(car_scenes))


func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
