@tool
extends TransmissionComponent
class_name GearBox

signal gear_changed

@export var gears: Array[float] = [-3.562, 3.615, 1.955, 1.286, 1.036, 0.839, 0.703]
@export var main_gear := 4.059

var gear_index: int:
	get: return gear_index

var gear_name: String:
	get: return "R" if gear < 0.0 else str(gear_index)

var gear: float:
	get(): return gears[gear_index] * main_gear if len(gears) > 0 else 1.0


func _ready() -> void:
	set_gear_index(1)


func gear_up() -> void:
	if gear_index + 1 < len(gears):
		set_gear_index(gear_index + 1)


func gear_down() -> void:
	if gear_index > 0:
		set_gear_index(gear_index - 1)


func set_gear_index(index: int) -> void:
	if index != gear_index and index >= 0 and index < len(gears):
		gear_index = index
		gear_changed.emit()


func set_reverse_gear() -> void:
	set_gear_index(0)
