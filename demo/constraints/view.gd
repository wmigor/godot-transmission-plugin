extends Node2D

var _solver := Solver.new()
var _motor := Shaft.new(0.1)
var _wheel := Shaft.new(0.3)
var _clutch_shaft := Shaft.new(0.1)
var _clutch := ClutchConstraint.new(_motor, _clutch_shaft, 101.0)
var _gearbox := GearConstraint.new(_clutch_shaft, _wheel, 2.0)
var _brake := BrakeConstraint.new(_wheel, 0.1, 0.8, 3000.0)


func _ready() -> void:
	_solver.shafts.append_array([_motor, _clutch_shaft, _wheel])
	_solver.constraints.append_array([_clutch, _gearbox, _brake])
	_clutch.clutch_pedal = $Clutch.value
	$Clutch.value_changed.connect(func(value: float): _clutch.clutch_pedal = value)
	_brake.pedal = $Brake.value
	$Brake.value_changed.connect(func(value: float): _brake.pedal = value)


func _physics_process(delta: float) -> void:
	_motor.torque = 100.0 - _motor.angular_velocity * PI - _motor.angular_velocity * 0.1
	_solver.step(delta)
	queue_redraw()


func _draw() -> void:
	for i in len(_solver.shafts):
		var color := Color.RED if _clutch.sliding else Color.GREEN
		_draw_shaft(_solver.shafts[i], Vector2(100, 100 + i * 100), 25.0, color)


func _draw_shaft(shaft: Shaft, center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color, false)
	var point = center + radius * Vector2(cos(shaft.angle), sin(shaft.angle))
	draw_line(center, point, color)
