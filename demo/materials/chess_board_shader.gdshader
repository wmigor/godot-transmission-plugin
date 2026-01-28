shader_type spatial;

uniform vec4 color_a : source_color = vec4(1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float cell_size = 100;
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
		? world_pos.xz / cell_size * 2.0
		: UV * cell_size * 2.0;
	float pattern = mod(floor(uv.x) + floor(uv.y), 2.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, pattern);
}