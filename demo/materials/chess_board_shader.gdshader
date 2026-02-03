shader_type spatial;

uniform vec4 color_a : source_color = vec4(1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_c : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_d : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float cell_size = 25;
uniform bool use_world_position = true;

varying vec3 world_pos;

void vertex()
{
	if (use_world_position)
		world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment()
{
	vec2 uv = use_world_position
		? world_pos.xz / cell_size
		: UV * cell_size;
	float pattern = mod(floor(uv.x) + floor(uv.y), 2.0);
	vec3 a = mix(color_a.rgb, color_b.rgb, pattern);
	uv = use_world_position
		? world_pos.xz / cell_size * 5.0
		: UV * cell_size * 5.0;
	pattern = mod(floor(uv.x) + floor(uv.y), 2.0);
	vec3 b = mix(color_c.rgb, color_d.rgb, pattern);
	ALBEDO = mix(a, b, 0.1);
}