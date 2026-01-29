@tool
extends Control

@export var curve: TorqueCurve
@export var torque_color := Color.GREEN
@export var power_color := Color.RED

var _cursor: Vector2
var _torque: float
var _torque_points := PackedVector2Array()
var _power_points := PackedVector2Array()
var _max_vertical_value: float


func _ready() -> void:
	if curve == null:
		curve = TorqueCurve.new()
	curve.changed.connect(_on_curve_changed)
	resized.connect(_on_curve_changed)
	_make_plot()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_set_mouse_position(get_local_mouse_position())


func _on_curve_changed() -> void:
	_make_plot()
	queue_redraw()


func _draw() -> void:
	_draw_plot()
	_draw_cursor()
	_draw_factors()


func _draw_cursor() -> void:
	draw_line(Vector2(_cursor.x, 0.0), Vector2(_cursor.x, size.y), Color.ORANGE)
	draw_line(Vector2(0.0, _cursor.y), Vector2(size.x, _cursor.y), Color.ORANGE)
	var font := ThemeDB.fallback_font
	var font_height := font.get_height()
	var v_scale := _get_vertical_scale()
	var rpm := _map_x_to_rpm(_cursor.x)
	var torque := (size.y - _cursor.y) / v_scale
	draw_string(font, Vector2(_cursor.x, size.y - font_height), str(int(rpm)))
	draw_string(font, Vector2(size.x - 90.0, _cursor.y + font_height * 0.5), str(snappedf(torque, 0.1)))


func _make_plot() -> void:
	_torque_points.clear()
	_power_points.clear()
	_max_vertical_value = 0.0
	for x in int(size.x):
		var rpm := _map_x_to_rpm(x)
		var torque := curve.get_torque(rpm / TorqueCurve.TO_RPM)
		var hp := curve.get_power(rpm / TorqueCurve.TO_RPM) / TorqueCurve.HP_TO_W
		_torque_points.append(Vector2(rpm, torque))
		_power_points.append(Vector2(rpm, hp))
		_max_vertical_value = max(_max_vertical_value, max(torque, hp))
	var v_scale := _get_vertical_scale()
	for i in len(_torque_points):
		_torque_points[i].x = _map_rpm_to_x(_torque_points[i].x)
		_torque_points[i].y = size.y - _torque_points[i].y * v_scale
	for i in len(_power_points):
		_power_points[i].x = _map_rpm_to_x(_power_points[i].x)
		_power_points[i].y = size.y - _power_points[i].y * v_scale


func _draw_plot() -> void:
	if len(_torque_points) > 1:
		draw_polyline(_torque_points, torque_color, 1.0, true)
	if len(_power_points) > 1:
		draw_polyline(_power_points, power_color, 1.0, true)


func _map_x_to_rpm(x: float) -> float:
	return curve.idle_rpm + x * (curve.max_rpm - curve.idle_rpm) / size.x


func _map_rpm_to_x(rpm: float) -> float:
	return size.x * (rpm - curve.idle_rpm) / (curve.max_rpm - curve.idle_rpm)


func _get_vertical_scale() -> float:
	return (size.y / _max_vertical_value) if _max_vertical_value != 0.0 else 1.0


func _draw_factors() -> void:
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	var font_height := font.get_height(font_size)
	var rpm := _map_x_to_rpm(_cursor.x)
	draw_string(font, Vector2(5, font_height + 0 * font_height), "RPM: " + str(int(rpm)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, font_height + 1 * font_height), "Torque: " + str(snappedf(_torque, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, torque_color)
	draw_string(font, Vector2(5, font_height + 2 * font_height), "HP: " + str(snappedf(curve.get_power(rpm / TorqueCurve.TO_RPM) / TorqueCurve.HP_TO_W, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, power_color)


func _input(event: InputEvent) -> void:
	if event as InputEventMouseMotion:
		_set_mouse_position(get_local_mouse_position())


func _set_mouse_position(pos: Vector2) -> void:
	if not get_rect().has_point(pos) or pos == _cursor or curve == null:
		return
	var rpm := _map_x_to_rpm(pos.x)
	_cursor = pos
	_torque = curve.get_torque(rpm / TorqueCurve.TO_RPM)
	queue_redraw()
