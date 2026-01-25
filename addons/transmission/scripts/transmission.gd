extends Node
class_name Transmission

@export var input_throttle := 0.0

@onready var motor := $Motor as Motor
@onready var gear_box := $GearBox as GearBox
@onready var clutch := $Clutch as Clutch
@onready var differential := $Differential as Differential


func _physics_process(delta: float) -> void:
	if motor == null or gear_box == null or clutch == null or differential == null:
		return
	var gear := gear_box.gear
	var axle_inertia := differential.get_axle_inertia()
	var axle_av := differential.get_axle_angular_velocity()
	motor.update_torque(input_throttle)
	clutch.calculate(delta, motor, gear_box, differential)
