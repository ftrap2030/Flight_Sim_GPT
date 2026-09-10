shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 block = floor(world.xz / 155.0);
	vec2 cell = abs(fract(world.xz / 155.0) - 0.5);
	float edge = max(cell.x, cell.y);
	float roads = smoothstep(0.452, 0.47, edge);
	float r = hash(block);
	vec3 grass = mix(vec3(0.045,0.075,0.025), vec3(0.09,0.12,0.06),r);
	vec3 suburb = mix(grass,vec3(0.19,0.18,0.145),step(0.3,r)*0.55);
	ALBEDO = mix(suburb,vec3(0.065,0.072,0.075),roads);
	ALBEDO += (hash(floor(world.xz * 1.5))-0.5)*0.022;
	ROUGHNESS = 0.95;
}
