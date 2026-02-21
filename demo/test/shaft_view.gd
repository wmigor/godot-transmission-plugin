@tool
extends Node2D
class_name ShaftView

@export var inertia := 1.0
@export var input_torque := 0.0
@export var friction := 0.0

@export var radius := 10.0:
	set(value):
		radius = value
		queue_redraw()

@export var color := Color.RED:
	set(value):
		color = value
		queue_redraw()

@onready var output := (get_child(0) as Shaftable) if get_child_count() > 0 else null

var angular_velocity: float
var torque: float
var angle: float


func update_velocity(delta: float) -> void:
	torque = input_torque - angular_velocity * friction
	angular_velocity += delta * torque / inertia
	angle += angular_velocity * delta
	if output != null:
		output.update_velocity(delta)
	queue_redraw()


func update(delta: float) -> void:
	if output != null:
		output.update(delta)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, false)
	draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * radius, color)
