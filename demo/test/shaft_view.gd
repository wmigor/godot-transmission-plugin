@tool
extends Node2D
class_name ShaftView

@export var inertia := 0.0
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

@onready var output := get_child(0) as Shaftable

var angular_velocity: float
var torque: float
var angle: float
var total_inertia: float
var raw_inertia: float


func update_feedback() -> void:
	output.update_feedback()


func update(delta: float) -> void:
	angular_velocity += delta * torque / total_inertia
	angle += angular_velocity * delta
	output.update(delta)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, false)
	draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * radius, color)
