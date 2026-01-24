extends Node3D


@onready var vehicle := $KiaRio as Car
@onready var rpm_label := $Hud/Grid/Rpm as Label
@onready var gear_label := $Hud/Grid/Gear as Label
@onready var speed_label := $Hud/Grid/Speed as Label


func _process(_delta: float) -> void:
	rpm_label.text = str(int(vehicle.transmission.motor.rpm))
	gear_label.text = str(1 + vehicle.transmission.gear_box.gear_index)
	speed_label.text = str(int(3.6 * vehicle.linear_velocity.dot(vehicle.basis.z))) + " km/h"
