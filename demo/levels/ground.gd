extends StaticBody3D

@export var generate_hills := true
@export var vertical_size := 64.0
@export var horizontal_scale := 6.0
@export var height_map_texture: Texture2D
@export var ground_material: Material


func _ready() -> void:
	if generate_hills:
		height_map_texture.changed.connect(_make_ground)


func _make_ground() -> void:
	var image := height_map_texture.get_image()
	image.convert(Image.FORMAT_RF)
	_create_shape(image)
	_create_mesh(image)


func _create_shape(image: Image) -> void:
	var height_map := HeightMapShape3D.new()
	height_map.update_map_data_from_image(image, -vertical_size * 0.5, vertical_size * 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = height_map
	shape.scale.x = horizontal_scale
	shape.scale.z = horizontal_scale
	add_child(shape)
	#shape.set_owner(get_tree().get_edited_scene_root())


func _create_mesh(image: Image) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(ground_material)
	var offset := -Vector3((image.get_width() - 1) * 0.5, 0.0, (image.get_height() - 1) * 0.5)
	for x in image.get_width() - 1:
		for y in image.get_height() - 1:
			var h00 := (image.get_pixel(x, y).r - 0.5) * vertical_size
			var h10 := (image.get_pixel(x + 1, y).r - 0.5) * vertical_size
			var h01 := (image.get_pixel(x, y + 1).r - 0.5) * vertical_size
			var h11 := (image.get_pixel(x + 1, y + 1).r - 0.5) * vertical_size
			tool.set_uv(Vector2(float(x) / image.get_width(), float(y) / image.get_height()))
			tool.add_vertex(offset + Vector3(x, h00, y))
			tool.set_uv(Vector2(float(x + 1) / image.get_width(), float(y) / image.get_height()))
			tool.add_vertex(offset + Vector3((x + 1), h10, y))
			tool.set_uv(Vector2(float(x) / image.get_width(), float(y + 1) / image.get_height()))
			tool.add_vertex(offset + Vector3(x, h01, (y + 1)))
			tool.set_uv(Vector2(float(x + 1) / image.get_width(), float(y + 1) / image.get_height()))
			tool.add_vertex(offset + Vector3((x + 1), h11, (y + 1)))
			tool.set_uv(Vector2(float(x) / image.get_width(), float(y + 1) / image.get_height()))
			tool.add_vertex(offset + Vector3(x, h01, (y + 1)))
			tool.set_uv(Vector2(float(x + 1) / image.get_width(), float(y) / image.get_height()))
			tool.add_vertex(offset + Vector3((x + 1), h10, y))
	tool.generate_normals()
	var mesh := tool.commit()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	mesh_instance.scale.x = horizontal_scale
	mesh_instance.scale.z = horizontal_scale
	
