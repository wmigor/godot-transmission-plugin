extends CanvasLayer
class_name Hud

@onready var rpm_label := $Grid/Rpm as Label
@onready var speed_label := $Grid/Speed as Label
@onready var gear_label := $Grid/Gear as Label
@onready var throttle_label := $Grid/Throttle as Label
@onready var clutch_label := $Grid/Clutch as Label
@onready var timer_label := $Timer as Label
@onready var torque_label := $Grid/Torque as Label
@onready var title := $Title as Label
@onready var rpm_view := $RpmView

var car: Car:
	set(value):
		car = value
		rpm_view.car = value
		title.text = car.title if car != null else ""


func _process(_delta: float) -> void:
	if car == null or car.transmission == null:
		return
	var transmission := car.transmission
	rpm_label.text = str(int(transmission.motor.rpm))
	speed_label.text = str(absf(int(3.6 * car.linear_velocity.dot(car.basis.z)))) + " km/h"
	gear_label.text = str(1 + transmission.gear_box.gear_index)
	throttle_label.text = str(snappedf(transmission.motor.input_throttle, 0.01))
	clutch_label.text = str(snappedf(transmission.clutch.input_value, 0.01)) + (" Locked" if transmission.clutch.clutch_locked else " Free")
	timer_label.text = str(snappedf(Time.get_ticks_msec() / 1000.0, 0.1))
	torque_label.text = str(roundi(car.transmission.motor.torque)) + " (" + str(roundi(car.transmission.motor.torque * car.transmission.gear_box.gear)) + ")"
