extends Node
class_name GearBox

signal gear_changed

@export var gears: Array[float] = [3.615, 1.955, 1.286, 1.036, 0.839, 0.703]
@export var main_gear := 4.059


var gear_index: int:
	get: return gear_index


var gear: float:
	get(): return gears[gear_index] * main_gear if len(gears) > 0 else 1.0


func gear_up() -> void:
	gear_index = mini(gear_index + 1, len(gears) - 1)


func gear_down() -> void:
	gear_index = max(gear_index - 1, 0)
