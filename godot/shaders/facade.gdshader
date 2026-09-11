shader_type spatial;
uniform float night_amount : hint_range(0.0,1.0) = 0.0;
varying vec3 world;
varying vec3 world_normal;
varying vec4 tint;
float hash(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	tint = COLOR;
}
void fragment() {
	float along = abs(world_normal.x) > 0.5 ? world.z : world.x;
	vec2 grid = vec2(along / 3.2, world.y / 3.6);
	vec2 uv = fract(grid);
	float window = step(0.16,uv.x)*step(uv.x,0.82)*step(0.19,uv.y)*step(uv.y,0.78);
	window = mix(window,0.43,smoothstep(0.3,1.1,max(fwidth(grid.x),fwidth(grid.y))));
	window *= 1.0-step(0.5,abs(world_normal.y));
	vec3 base = mix(vec3(0.26,0.28,0.25),vec3(0.12,0.19,0.22),tint.r);
	ALBEDO = mix(base,vec3(0.09,0.17,0.21),window);
	METALLIC = window * 0.35;
	ROUGHNESS = mix(0.85,0.30,window);
	float lit = step(0.43,hash(floor(grid)));
	EMISSION = vec3(1.0,0.72,0.36)*window*lit*night_amount*0.5;
}
