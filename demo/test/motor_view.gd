@tool
extends Node2D
class_name MotorView

@export var inertia := 0.1
@export var input_torque := 0.5
@export var friction := 0.0
@export var gear := 1.0

@export var radius := 10.0:
	set(value):
		radius = value
		queue_redraw()

@export var color := Color.GREEN:
	set(value):
		color = value
		queue_redraw()

@onready var output := (get_child(0) as ShaftView) if get_child_count() > 0 else null

var angular_velocity: float
var torque: float
var angle: float
var reaction_impulse: float
var reaction_torque: float


func update_velocity(delta: float) -> void:
	torque = input_torque - angular_velocity * friction
	angular_velocity += delta * torque / inertia
	angle += angular_velocity * delta
	if output != null:
		output.update_velocity(delta)
	queue_redraw()


func update(delta: float) -> void:
	if output == null:
		return
	output.update(delta)
	var error := angular_velocity - output.angular_velocity * gear
	reaction_impulse = -error / (1.0 / inertia + gear * gear / output.inertia)
	reaction_torque = reaction_impulse / delta
	angular_velocity += reaction_impulse / inertia
	output.angular_velocity -= reaction_impulse * gear / output.inertia


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, false)
	draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * radius, color)
