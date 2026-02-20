@tool
extends Shaftable
class_name WheelView

@export var inertia := 1.0
@export var input_torque := 0.0
@export var friction := 0.1

@export var radius := 50.0:
	set(value):
		radius = value
		queue_redraw()

@export var color := Color.BLACK:
	set(value):
		color = value
		queue_redraw()


func update_feedback() -> void:
	input_shaft.torque = input_torque - input_shaft.angular_velocity * friction
	input_shaft.total_inertia = input_shaft.inertia + inertia


func update(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, false)
	draw_line(Vector2.ZERO, Vector2(cos(input_shaft.angle), sin(input_shaft.angle)) * radius, color)
