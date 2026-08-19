extends RigidBody3D
class_name CustomCar

@export var _torque_curve: TorqueCurve
@export var _gears: Array[float] = [3.615, 1.955, 1.286, 1.036, 0.839, 0.703]
@export var _main_gear := 4.059

class Susp:
	var pos: Vector3
	var rest_length := 1.0
	var direction := Vector3.DOWN
	var stiffness := 40000.0
	var damping_bump := 4000.0
	var damping_rebound := 4000.0

	var accumulated_impulse: float
	var friction_coefficient := 0.8
	var tire_stiffness := 5000.0

var _gear_index: int
var _solver := Solver.new()
var _susps: Array[Susp]
var _tires: Array[TireConstraint]
var _ground := Plane(Vector3.UP, 0.0)

var _motor := Shaft.new(0.1)
var _cardan := Shaft.new(0.1)
var _wheels: Array[Shaft] = [Shaft.new(0.3), Shaft.new(0.3), Shaft.new(0.3), Shaft.new(0.3)]
var _gearbox := GearBoxConstraint.new(_motor, _cardan, 250.0, 14)
var _differential := DifferencialConstraint.new(_cardan, _wheels[0], _wheels[1])
var _brake1 := BrakeConstraint.new(_wheels[0], 0.1, 0.8, 30000.0)
var _brake2 := BrakeConstraint.new(_wheels[1], 0.1, 0.8, 30000.0)

@onready var _motor_constraint := MotorConstraint.new(_motor, _torque_curve)
@onready var _rpm_view := $RpmView

var body_state: PhysicsDirectBodyState3D



func _ready() -> void:
	gravity_scale = 0.0
	
	var susp := Susp.new()
	susp.pos.x = 0.78
	susp.pos.z = 1.35
	_susps.append(susp)
	
	susp = Susp.new()
	susp.pos.x = -0.78
	susp.pos.z = 1.35
	_susps.append(susp)
	
	susp = Susp.new()
	susp.pos.x = -0.78
	susp.pos.z = -1.35
	_susps.append(susp)
	
	susp = Susp.new()
	susp.pos.x = 0.78
	susp.pos.z = -1.35
	_susps.append(susp)

	for s in _susps:
		_solver.constraints.append(SuspensionConstraint.new(self, s, _ground))
	
	for i in len(_susps):
		var tire = TireConstraint.new(self, _susps[i], _ground, _wheels[i], 0.3)
		_tires.append(tire)
		_solver.constraints.append(tire)

	_solver.shafts.append_array([_motor, _cardan])
	_solver.shafts.append_array(_wheels)
	_solver.constraints.append_array([_motor_constraint, _gearbox, _differential, _brake1, _brake2])

	_gear_index = -1
	set__gear_index(0)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_process_mouse_control()
	_rpm_view.set_rpm(_motor.rpm, _torque_curve.max_rpm)
	body_state = state
	linear_velocity.y -= 9.8 * state.step
	_solve(state.step)
	state.integrate_forces()


func  _solve(delta: float) -> void:
	_solver.step(delta)


func _process_mouse_control() -> void:
	var viewport := get_viewport()
	var width := viewport.get_visible_rect().size.x
	var x := get_viewport().get_mouse_position().x
	var angle := deg_to_rad(45.0) * clampf(2.0 * (width / 2.0 - x) / width, -1.0, 1.0)
	_tires[2].angle = angle
	_tires[3].angle = angle


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("brake_key"):
		_brake1.pedal = 1.0
		_brake2.pedal = 1.0
	elif event.is_action_released("brake_key"):
		_brake1.pedal = 0.0
		_brake2.pedal = 0.0
	elif event.is_action_pressed("gear_up"):
		gear_up()
	elif event.is_action_pressed("gear_down"):
		gear_down()


func gear_up() -> void:
	if _gear_index + 1 < len(_gears):
		set__gear_index(_gear_index + 1)


func gear_down() -> void:
	if _gear_index > 0:
		set__gear_index(_gear_index - 1)


func set__gear_index(index: int) -> void:
	if index != _gear_index and index >= 0 and index < len(_gears):
		_gear_index = index
		_gearbox.shift_gear(_gears[_gear_index] * _main_gear)
