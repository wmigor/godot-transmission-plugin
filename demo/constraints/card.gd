extends RigidBody3D

class Susp:
	var pos: Vector3
	var length := 1.0
	var direction := Vector3.DOWN
	var stiffness := 1000.0
	var damping := 1.0

var _solver := Solver.new()
var _susps: Array[Susp]
var _ground := Plane(Vector3.UP, 0.0)
var body_state: PhysicsDirectBodyState3D


func _ready() -> void:
	gravity_scale = 0.0
	_susps.append(Susp.new())


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	body_state = state
	linear_velocity.y -= 9.8 * state.step
	_solve(state.step)
	state.integrate_forces()
	print(get_susp_length(_susps[0]))


func  _solve(delta: float) -> void:
	_solver.step(delta)


func get_susp_length(susp: Susp) -> float:
	var pos := global_transform * susp.pos
	var dir := global_basis * susp.direction
	var point = _ground.intersects_ray(pos, dir)
	if point == null:
		return susp.length
	var distance := pos.distance_to(point)
	return minf(susp.length, distance)
