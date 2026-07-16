extends RigidBody3D
class_name CustomCar

class Susp:
	var pos: Vector3
	var rest_length := 1.0
	var direction := Vector3.DOWN
	var stiffness := 20000.0
	var damping_bump := 500.0
	var damping_rebound := 1000.0

	var accumulated_impulse: float
	var friction_coefficient := 0.8
	var tire_stiffness := 5000.0

var _solver := Solver.new()
var _susps: Array[Susp]
var _tires: Array[TireConstraint]
var _ground := Plane(Vector3.UP, 0.0)

var _motor := Shaft.new(0.1)
var _cardan := Shaft.new(0.1)
var _wheels: Array[Shaft] = [Shaft.new(0.3), Shaft.new(0.3), Shaft.new(0.3), Shaft.new(0.3)]
var _gearbox := GearBoxConstraint.new(_motor, _cardan, 125.0, 14)
var _differential := DifferencialConstraint.new(_cardan, _wheels[0], _wheels[1])
var _brake1 := BrakeConstraint.new(_wheels[0], 0.1, 0.8, 3000.0)
var _brake2 := BrakeConstraint.new(_wheels[1], 0.1, 0.8, 3000.0)

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
	_tires[2].angle = deg_to_rad(45)
	_tires[3].angle = deg_to_rad(45)

	_solver.shafts.append_array([_motor, _cardan])
	_solver.shafts.append_array(_wheels)
	_solver.constraints.append_array([_gearbox, _differential, _brake1, _brake2])


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	body_state = state
	_motor.torque = 100.0 - _motor.angular_velocity * 0.1
	linear_velocity.y -= 9.8 * state.step
	_solve(state.step)
	state.integrate_forces()


func  _solve(delta: float) -> void:
	_solver.step(delta)
