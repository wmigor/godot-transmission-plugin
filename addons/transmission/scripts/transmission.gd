extends Node
class_name Transmission

@export_range(-1.0, 1.0, 0.001) var input_steering: float
@export_range(-1.0, 1.0, 0.001) var input_brake: float
@export_range(-1.0, 1.0, 0.001) var input_hand_brake: float

@onready var motor := $Motor as Motor
@onready var gear_box := $GearBox as GearBox
@onready var clutch := $Clutch as Clutch
@onready var differential := $Differential as Differential

var _anti_roll_bars: Array[AntiRollBar]


func _ready() -> void:
	_anti_roll_bars.append_array(find_children("*", "AntiRollBar"))


func _physics_process(delta: float) -> void:
	if motor == null or gear_box == null or clutch == null or differential == null:
		return
	var gear := gear_box.gear
	var axle_inertia := differential.get_axle_inertia()
	var axle_av := differential.get_axle_angular_velocity()
	for anti_roll_bar in _anti_roll_bars:
		anti_roll_bar.update_forces()
	differential.update(delta, input_steering)
	motor.update_torque()
	clutch.calculate(delta, motor, differential, gear_box.gear)
	differential.after_update(delta, clutch.input_value * motor.input_throttle <= 0.05, input_brake, input_hand_brake)
