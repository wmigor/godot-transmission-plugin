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
	if gear_index + 1 < len(gears):
		gear_index += 1
		gear_changed.emit()


func gear_down() -> void:
	if gear_index > 0:
		gear_index -= 1
		gear_changed.emit()
