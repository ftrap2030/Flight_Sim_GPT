shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.015, 0.16, 0.22);
uniform vec3 shallow_color : source_color = vec3(0.08, 0.39, 0.40);
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float a = sin(world.x * 0.17 + world.z * 0.11 + TIME * 1.2) * 0.55 + sin(world.x * -0.08 + world.z * 0.23 - TIME * 0.8) * 0.28 + sin(world.x * 0.33 + world.z * 0.31 + TIME * 0.5) * 0.17;
	float b = sin(world.x * 0.027 + world.z * 0.045 + TIME * 0.45);
	float shoal = smoothstep(-0.8, 0.8, sin(world.x * 0.0004) * cos(world.z * 0.0003));
	ALBEDO = mix(deep_color, shallow_color, shoal * 0.55) + a * 0.008;
	NORMAL_MAP = normalize(vec3(a * 0.035, b * 0.025, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.32 + a * 0.025;
	METALLIC = 0.25;
	SPECULAR = 0.8;
}
