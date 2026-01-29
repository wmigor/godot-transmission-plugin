extends Node
class_name AutoShiftGear

@export var min_rpm := 1500.0
@export var max_rpm := 6300.0
@export var delay := 0.5

var _timer := 0.0


func update(delta: float, gear_box: GearBox, motor: Motor) -> void:
	if _timer > 0.0:
		_timer -= delta
		return
	if motor.rpm >= max_rpm and gear_box.gear_index < len(gear_box.gears):
		_timer = delay
		gear_box.gear_up()
	elif motor.rpm <= min_rpm and gear_box.gear_index > 0:
		_timer = delay
		gear_box.gear_down()
