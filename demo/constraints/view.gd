extends Node2D

var _solver := Solver.new()
var _motor := Shaft.new(0.1)
var _wheel1 := Shaft.new(0.3)
var _wheel2 := Shaft.new(0.3)
var _clutch_shaft := Shaft.new(0.1)
var _differencial_in := Shaft.new(0.3)
var _clutch := ClutchConstraint.new(_motor, _clutch_shaft, 101.0)
var _gearbox := GearConstraint.new(_clutch_shaft, _differencial_in, 2.0)
var _differential := DifferencialConstraint.new(_differencial_in, _wheel1, _wheel2)
var _brake1 := BrakeConstraint.new(_wheel1, 0.1, 0.8, 3000.0)
var _brake2 := BrakeConstraint.new(_wheel2, 0.1, 0.8, 3000.0)


func _ready() -> void:
	_solver.shafts.append_array([_motor, _clutch_shaft, _differencial_in, _wheel1, _wheel2])
	_solver.constraints.append_array([_clutch, _gearbox, _differential, _brake1, _brake2])
	_clutch.clutch_pedal = $Clutch.value
	$Clutch.value_changed.connect(func(value: float): _clutch.clutch_pedal = value)
	_brake1.pedal = $Brake.value
	$Brake.value_changed.connect(func(value: float): _brake1.pedal = value)
	_brake2.pedal = $Brake2.value
	$Brake2.value_changed.connect(func(value: float): _brake2.pedal = value)
	_gearbox.shift_gear($Gear.value)
	$Gear.value_changed.connect(func(value: float): _gearbox.shift_gear(value))


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
