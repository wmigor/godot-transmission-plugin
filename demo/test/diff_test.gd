extends Node2D

@onready var input_shaft := $InputShaft as ShaftView
var av: float
var time: float

func _physics_process(delta: float) -> void:
	var old := input_shaft.angular_velocity
	input_shaft.update_feedback()
	input_shaft.update(delta)
	time += delta
	if old < 1 and input_shaft.angular_velocity >= 1:
		print("shaft time: ", time)
	old = av
	av += input_shaft.input_torque * delta
	if old < 1 and av >= 1:
		print("av time: ", time)
	
	#print(av, ' ', input_shaft.angular_velocity, ' ', 0.5 * ($InputShaft/CentralDifferential/LeftShaft.angular_velocity + $InputShaft/CentralDifferential/RightShaft.angular_velocity))
	#print(int(rad_to_deg(input_shaft.angle)), ' ', int(rad_to_deg(0.5 * $InputShaft/CentralDifferential/RightShaft.angle)))
