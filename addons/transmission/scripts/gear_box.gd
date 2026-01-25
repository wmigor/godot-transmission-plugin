extends Node
class_name GearBox

signal gear_changed

@export var gears: Array[float] = [3.615, 1.955, 1.286, 1.036, 0.839, 0.703]
@export var main_gear := 4.059

var _target_gear_index: int

var gear_index: int:
	get: return gear_index


var gear: float:
	get(): return gears[gear_index] * main_gear if len(gears) > 0 else 1.0


func update(clutch: Clutch) -> void:
	if _target_gear_index != gear_index:
		gear_index = _target_gear_index
		clutch.clutch_locked = false


func gear_up() -> void:
	_target_gear_index = mini(_target_gear_index + 1, len(gears) - 1)


func gear_down() -> void:
	_target_gear_index = max(_target_gear_index - 1, 0)
