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
var _ground := Plane(Vector3.UP, 0.0)
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
	var tires: Array[TireConstraint]
	for s in _susps:
		var wheel := Shaft.new(0.3)
		var tire = TireConstraint.new(self, s, _ground, wheel, 0.3)
		tires.append(tire)
		_solver.constraints.append(tire)
	tires[2].angle = deg_to_rad(45)
	tires[3].angle = deg_to_rad(45)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	body_state = state
	linear_velocity.y -= 9.8 * state.step
	_solve(state.step)
	state.integrate_forces()


func  _solve(delta: float) -> void:
	_solver.step(delta)
