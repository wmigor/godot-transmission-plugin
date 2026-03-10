extends Node2D


class Body:
	var mass := 1.0
	var position: Vector2
	var linear_velocity: Vector2

	func _init(position_: Vector2) -> void:
		position = position_

	func apply_impulse(impulse: Vector2) -> void:
		linear_velocity += impulse / mass


class Spring:
	var frequency := 1.0
	var stiffness := 0.0
	var damping := 0.2
	var rest_length := 64.0
	var body1: Body
	var body2: Body

	func _init(body1_: Body, body2_: Body) -> void:
		body1 = body1_
		body2 = body2_


var _bodies: Array[Body]
var _springs: Array[Spring]


func _ready() -> void:
	_bodies.append(Body.new(Vector2(100, 100)))
	_bodies.append(Body.new(Vector2(200, 100)))
	_bodies.append(Body.new(Vector2(200, 200)))
	_bodies.append(Body.new(Vector2(100, 200)))

	_springs.append(Spring.new(_bodies[0], _bodies[1]))
	_springs.append(Spring.new(_bodies[1], _bodies[2]))
	_springs.append(Spring.new(_bodies[2], _bodies[3]))
	_springs.append(Spring.new(_bodies[3], _bodies[0]))
	_springs.append(Spring.new(_bodies[0], _bodies[2]))
	_springs.append(Spring.new(_bodies[1], _bodies[3]))


func _process(_delta: float) -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	_simulate(delta)


func _simulate(delta: float) -> void:
	for spring in _springs:
		var body1 := spring.body1
		var body2 := spring.body2
		var vector := body2.position - body1.position
		var direction = vector.normalized()
		var velocity := (body2.linear_velocity - body1.linear_velocity).dot(direction)
		var length := vector.dot(direction)
		var inv_effective_mass := 1.0 / body1.mass + 1.0 / body2.mass
		var effective_mass := 1.0 / inv_effective_mass
		var error := length - spring.rest_length
		var stiffness := spring.stiffness
		var damping := spring.damping
		if stiffness <= 0.0 and spring.frequency > 0.0:
			var omega := TAU * spring.frequency
			stiffness = effective_mass * omega * omega
			damping = 2.0 * effective_mass * spring.damping * omega
		var softness := 1.0 / (delta * (damping + delta * stiffness))
		var bias := delta * stiffness / (damping + delta * stiffness)
		effective_mass = 1.0 / (inv_effective_mass + softness)
		var impulse := -(bias * error / delta + velocity) * effective_mass
		body1.apply_impulse(-impulse * direction)
		body2.apply_impulse(impulse * direction)
	for body in _bodies:
		body.position += body.linear_velocity * delta


func _draw() -> void:
	for spring in _springs:
		draw_line(spring.body1.position, spring.body2.position, Color.GREEN)
	for body in _bodies:
		draw_circle(body.position, 16.0, Color.RED, false)
