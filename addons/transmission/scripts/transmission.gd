extends Node
class_name Transmission

@export_range(-1.0, 1.0, 0.001) var input_steering: float
@export_range(-1.0, 1.0, 0.001) var input_brake: float
@export_range(-1.0, 1.0, 0.001) var input_hand_brake: float

@onready var motor := $Motor as Motor
@onready var gear_box := $GearBox as GearBox
@onready var clutch := $Clutch as Clutch
@onready var differential := $Differential as Differential

var _systems: Dictionary[String, System]


func _ready() -> void:
	for system in find_children("*", "System"):
		_systems[system.name] = system
	set_physics_process(false)
	set_physics_process.call_deferred(true)


func _physics_process(delta: float) -> void:
	if motor == null or gear_box == null or clutch == null or differential == null:
		return
	for system in _systems.values():
		system.update(delta)
	differential.update(delta, input_steering)
	motor.update_torque()
	clutch.calculate(delta, motor, differential, gear_box.gear)
	differential.after_update(delta, clutch.input_value * motor.input_throttle <= 0.0, input_brake, input_hand_brake)


func get_system(system_name: String) -> System:
	return _systems.get(system_name)
