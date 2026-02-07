@tool
extends System
class_name AutoShiftGear

@export var min_rpm := 1500.0
@export var max_rpm := 6300.0
@export var delay := 0.5
@export var wheel_radius := 0.316

var _body: RigidBody3D 
var _timer := 0.0


func _ready() -> void:
	if transmission != null:
		_body = transmission.get_parent() as RigidBody3D


func update(delta: float) -> void:
	if transmission == null or _body == null or not enabled:
		return
	var gear_box := transmission.gear_box
	var motor := transmission.motor
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			indicator = false
		return
	var rpm_from_wheel := _body.linear_velocity.length() / wheel_radius * gear_box.gear * TorqueCurve.TO_RPM
	var rpm_prev_gear := motor.rpm / gear_box.gear * gear_box.prev_gear
	if motor.rpm >= max_rpm and rpm_from_wheel >= max_rpm * 0.98 and gear_box.gear_index < len(gear_box.gears):
		_timer = delay
		indicator = true
		gear_box.gear_up()
	elif rpm_prev_gear <= max_rpm - max_rpm * 0.02 and gear_box.gear_index > 1:
		_timer = delay
		indicator = true
		gear_box.gear_down()
