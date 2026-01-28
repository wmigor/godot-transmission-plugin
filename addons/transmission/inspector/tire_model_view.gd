@tool
extends Control

@export var tire_model: TireModel:
	set(value):
		if tire_model != null:
			tire_model.changed.disconnect(queue_redraw)
		tire_model = value
		if tire_model != null:
			tire_model.changed.connect(queue_redraw)
		queue_redraw()

@export var grid_step := 0.2

@onready var _slip_ratio: HSlider

var interval := 90.0

var _cursor: Vector2
var _value: float

var max_value: float:
	get: return tire_model.peak * 1.1 if tire_model != null else 1.1


func _ready() -> void:
	_slip_ratio = HSlider.new()
	_slip_ratio.max_value = 1.0
	_slip_ratio.min_value = -1.0
	_slip_ratio.step = 0.01
	_slip_ratio.value = 0.0
	_slip_ratio.set_size(Vector2(100, 60))
	_slip_ratio.position = Vector2(100, 10)
	_slip_ratio.value_changed.connect(func(value: float): queue_redraw())
	add_child(_slip_ratio)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_set_mouse_position(get_local_mouse_position())


func _draw() -> void:
	_draw_grid()
	_draw_plot()
	_draw_axis()
	_draw_cursor()
	_draw_factors()


func _draw_grid() -> void:
	var count := int(max_value / grid_step)
	var v_scale := _get_vertical_scale()
	var center := size * 0.5
	var font_height := ThemeDB.fallback_font.get_height()
	for i in count:
		var value := (i + 1) * grid_step
		var y := value * v_scale
		draw_line(Vector2(0.0, center.y - y), Vector2(size.x, center.y - y), Color.SLATE_GRAY)
		draw_line(Vector2(0.0, center.y + y), Vector2(size.x, center.y + y), Color.SLATE_GRAY)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, center.y - y + font_height / 2.0), str(snappedf(value, 0.1)))
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 30, center.y + y + font_height / 2.0), str(snappedf(-value, 0.1)))


func _draw_axis() -> void:
	var center := size * 0.5
	draw_line(Vector2(0.0, center.y), Vector2(size.x, center.y), Color.WHITE)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, size.y), Color.WHITE)


func _draw_cursor() -> void:
	draw_line(Vector2(_cursor.x, 0.0), Vector2(_cursor.x, size.y), Color.ORANGE)
	draw_line(Vector2(0.0, _cursor.y), Vector2(size.x, _cursor.y), Color.ORANGE)
	var font := ThemeDB.fallback_font
	var font_height := font.get_height()
	var v_scale := _get_vertical_scale()
	var center := size * 0.5
	var angle := _map_x_to_angle(_cursor.x)
	var ratio := 2.0 * angle / PI
	draw_string(font, Vector2(_cursor.x, size.y - font_height), str(snappedf(rad_to_deg(angle), 0.001)) + "° (" + str(snappedf(ratio, 0.001)) + ")")
	draw_string(font, Vector2(size.x - 90.0, _cursor.y + font_height * 0.5), str(snappedf((center.y - _cursor.y) / v_scale, 0.001)))


func _get_vertical_scale() -> float:
	return size.y / max_value / 2.0


func _draw_plot() -> void:
	if tire_model == null:
		return
	var rect := get_rect()
	var v_scale := _get_vertical_scale()
	var center := size * 0.5
	var x := 0.0
	var points := PackedVector2Array()
	while x <= size.x:
		var angle := _map_x_to_angle(x)
		var value := tire_model.get_value(angle)
		var y := center.y - value * v_scale
		points.append(Vector2(x, y))
		x += 1
	draw_polyline(points, Color.GREEN, 1.0, true)


func _draw_factors() -> void:
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	var font_height := font.get_height(font_size)
	var angle := rad_to_deg(_map_x_to_angle(_cursor.x))
	draw_string(font, Vector2(5, 1 * font_height), "Angle: " + str(snappedf(angle, 0.001)) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, 2 * font_height), "Ratio: " + str(snappedf(_slip_ratio.value, 0.001)) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, 3 * font_height), "Value: " + str(snappedf(_value, 0.001)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.GREEN)


func _map_x_to_angle(x: float) -> float:
	var s := interval / 180.0
	return wrapf(deg_to_rad(x * 360.0 * s / size.x - interval), -PI, PI)


func _input(event: InputEvent) -> void:
	if event as InputEventMouseMotion:
		_set_mouse_position(get_local_mouse_position())
	elif event.is_action_pressed("ui_up"):
		interval -= 10.0
	elif event.is_action_pressed("ui_down"):
		interval += 10.0


func _set_mouse_position(pos: Vector2) -> void:
	if not get_rect().has_point(pos) or pos == _cursor:
		return
	var angle := _map_x_to_angle(pos.x)
	_cursor = pos
	_value = tire_model.get_value(angle)
	queue_redraw()


func _add_slider_to_grid(grid: GridContainer, title: String, slider: Slider) -> void:
	var title_label := Label.new()
	title_label.text = title
	var value_label := Label.new()
	value_label.text = "0.0"
	var container := HBoxContainer.new()
	container.add_child(value_label)
	container.add_child(slider)
	grid.add_child(title_label)
	grid.add_child(container)
	value_label.custom_minimum_size.x = 50
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	slider.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	value_label.size_flags_horizontal = Control.SIZE_FILL
	slider.value_changed.connect(func(value): value_label.text = str(value))
