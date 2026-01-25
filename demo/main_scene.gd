extends Node3D


@onready var car := $KiaRio as RigidBody3D
@onready var transmission := $KiaRio/Transmission as Transmission
@onready var rpm_label := $Hud/Grid/Rpm as Label
@onready var speed_label := $Hud/Grid/Speed as Label
@onready var gear_label := $Hud/Grid/Gear as Label
@onready var throttle_label := $Hud/Grid/Throttle as Label
@onready var clutch_label := $Hud/Grid/Clutch as Label


func _process(_delta: float) -> void:
	rpm_label.text = str(int(transmission.motor.rpm))
	speed_label.text = str(int(3.6 * car.linear_velocity.dot(car.basis.z))) + " km/h"
	gear_label.text = str(1 + transmission.gear_box.gear_index)
	throttle_label.text = str(snappedf(transmission.motor.input_throttle, 0.01))
	clutch_label.text = str(snappedf(transmission.clutch.input_value, 0.01)) + (" Locked" if transmission.clutch.clutch_locked else " Free")
