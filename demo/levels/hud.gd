extends CanvasLayer
class_name Hud

@onready var rpm_label := $Grid/Rpm as Label
@onready var speed_label := $Grid/Speed as Label
@onready var gear_label := $Grid/Gear as Label
@onready var throttle_label := $Grid/Throttle as Label
@onready var clutch_label := $Grid/Clutch as Label
@onready var timer_label := $Timer as Label
@onready var torque_label := $Grid/Torque as Label
@onready var brake_label := $Grid/Brake as Label
@onready var mode_label := $Grid/Mode as Label
@onready var differential_label := $Grid/Differential as Label
@onready var tcs_label := $Grid/Tcs as Label
@onready var title := $Title as Label
@onready var rpm_view := $RpmView

var player_controller
var car: Car:
	set(value):
		car = value
		rpm_view.car = value
		title.text = car.title if car != null else ""
		player_controller = null
		if car != null:
			player_controller = car.find_child("PlayerController")
			_on_car_changed()


func _process(_delta: float) -> void:
	if car == null or car.transmission == null:
		return
	var transmission := car.transmission
	rpm_label.text = str(int(transmission.motor.rpm))
	speed_label.text = str(absi(int(3.6 * car.linear_velocity.dot(car.basis.z)))) + " km/h"
	gear_label.text = transmission.gear_box.gear_name
	throttle_label.text = str(snappedf(minf(transmission.motor.throttle_limit, transmission.motor.input_throttle), 0.01))
	clutch_label.text = str(snappedf(transmission.clutch.input_value, 0.01)) + (" Locked" if transmission.clutch.clutch_locked else " Free")
	timer_label.text = str(snappedf(Time.get_ticks_msec() / 1000.0, 0.1))
	torque_label.text = str(roundi(car.transmission.motor.torque)) + " (" + str(roundi(car.transmission.motor.torque * car.transmission.gear_box.gear)) + ")"
	brake_label.text = str(snappedf(car.transmission.input_brake, 0.01))
	differential_label.text = car.transmission.differential.get_type_name()
	_update_mode()


func _update_mode() -> void:
	if player_controller == null:
		mode_label.text = ""
	else:
		mode_label.text = "Clutch" if player_controller.clutch_mode else "Brake"


func _on_car_changed() -> void:
	if car == null:
		return
	var tcs := car.transmission.get_system("Tcs") as Tcs
	if tcs == null:
		return
	_connect_system(tcs, tcs_label)


func _connect_system(system: System, label: Label) -> void:
	label.text = "ON" if system.enabled else "OFF"
	system.enable_changed.connect(func(enabled: bool): label.text = "ON" if enabled else "OFF")
	label.self_modulate = Color.RED if system.indicator else Color.WHITE
	system.indicator_changed.connect(func(indicator: bool): label.self_modulate = Color.RED if system.indicator else Color.WHITE)
