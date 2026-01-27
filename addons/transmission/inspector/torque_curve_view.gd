@tool
extends Control

@export var curve: TorqueCurve

var _cursor: Vector2
var _torque: float


func _ready() -> void:
	if curve == null:
		curve = TorqueCurve.new()
	curve.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_set_mouse_position(get_local_mouse_position())


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


func _get_vertical_scale() -> float:
	return size.y / curve.max_torque


func _draw_plot() -> void:
	if curve == null:
		return
	var rect := get_rect()
	var v_scale := _get_vertical_scale()
	var torque_points := PackedVector2Array()
	var x := 0.0
	while x <= size.x:
		var rpm := _map_x_to_rpm(x)
		var torque := curve.get_torque(rpm / TorqueCurve.TO_RPM)
		torque_points.append(Vector2(x, size.y - torque * v_scale))
		x += 1
	draw_polyline(torque_points, Color.GREEN, 1.0, true)


func _map_x_to_rpm(x: float) -> float:
	return curve.idle_rpm + x * (curve.max_rpm - curve.idle_rpm) / size.x


func _draw_factors() -> void:
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	var font_height := font.get_height(font_size)
	var rpm := _map_x_to_rpm(_cursor.x)
	draw_string(font, Vector2(5, size.y - font_height - 3 * font_height), "RPM: " + str(int(rpm)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, size.y - font_height - 2 * font_height), "Torque: " + str(snappedf(_torque, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, size.y - font_height - 1 * font_height), "HP: " + str(snappedf(curve.get_power(rpm / TorqueCurve.TO_RPM) / TorqueCurve.HP_TO_W, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


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
