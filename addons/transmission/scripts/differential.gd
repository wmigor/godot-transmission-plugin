@tool
extends Node
class_name Differential

enum Type {Auto, Open, Spool}

@export var left_node: NodePath
@export var right_node: NodePath
@export var type := Type.Auto
@export var auto_differential_lock_input_torque := 25.0
@export var auto_differential_slip_max := 0.35

var _left: Node
var _right: Node
var _vehicle: RigidBody3D
var shaft := Shaft.new()
var left_shaft := Shaft.new()
var right_shaft := Shaft.new()


func _ready() -> void:
	_left = get_node(left_node)
	_right = get_node(right_node)
	if _left is Wheel or _left is Differential:
		_left.shaft = left_shaft
	if _right is Wheel or _right is Differential:
		_right.shaft = right_shaft
	var wheels := get_parent() as Wheels
	if wheels == null:
		return
	var transmission := wheels.transmission
	if transmission == null:
		return
	_vehicle = transmission.get_parent() as RigidBody3D


func apply_torque(delta: float) -> void:
	var input_torque := shaft.torque
	if type == Type.Spool:
		var axle_av := get_axle_angular_velocity()
		var axle_inertia := get_axle_inertia()
		axle_av += delta * input_torque / axle_inertia
		left_shaft.torque = (axle_av - left_shaft.angular_velocity) * left_shaft.inertia / delta
		right_shaft.torque = (axle_av - right_shaft.angular_velocity) * right_shaft.inertia / delta
	elif type == Type.Open:
		var spider_torque := left_shaft.torque - right_shaft.torque
		var torque0 := input_torque * 0.5 + spider_torque
		var torque1 := input_torque * 0.5 - spider_torque
		left_shaft.torque = torque0
		right_shaft.torque = torque1
	elif type == Type.Auto:
		var spider_torque := left_shaft.torque - right_shaft.torque
		var locked_torque := input_torque / auto_differential_lock_input_torque
		var rate := 1.0 - exp(-locked_torque * locked_torque) if locked_torque > 0.0 else 0.0
		var pressure := tanh(rate * (right_shaft.angular_velocity - left_shaft.angular_velocity))
		var bias := auto_differential_slip_max * 0.5 * pressure
		var open := 1.0 - rate
		var torque0 := input_torque * (0.5 + bias) + spider_torque * open
		var torque1 := input_torque * (0.5 - bias) - spider_torque * open
		left_shaft.torque = torque0
		right_shaft.torque = torque1
	_left.apply_torque(delta)
	_right.apply_torque(delta)


func update_shafts() -> void:
	_left.update_shafts()
	_right.update_shafts()
	shaft.inertia = get_axle_inertia()
	shaft.torque = get_axle_torque()
	shaft.angular_velocity = get_axle_angular_velocity()
	shaft.brake_torque = 0.5 * (left_shaft.brake_torque + right_shaft.brake_torque)


func find_wheels(wheels: Array[Wheel]) -> void:
	if _left is Wheel:
		wheels.append(_left)
	elif _left is Differential:
		_left.find_wheels(wheels)
	if _right is Wheel:
		wheels.append(_right)
	elif _right is Differential:
		_right.find_wheels(wheels)


func get_axle_inertia() -> float:
	return left_shaft.inertia + right_shaft.inertia


func get_axle_angular_velocity() -> float:
	return 0.5 * (left_shaft.angular_velocity + right_shaft.angular_velocity)


func get_axle_torque() -> float:
	return 0.5 * (left_shaft.torque + left_shaft.brake_torque + right_shaft.torque + right_shaft.brake_torque)


func switch() -> void:
	type = ((type as int + 1) % 3) as Type
	if _left is Differential:
		_left.type = type
	if _right is Differential:
		_right.type = type


func get_type_name() -> String:
	if type == Type.Auto:
		return "Auto"
	if type == Type.Open:
		return "Open"
	return "Spool"
