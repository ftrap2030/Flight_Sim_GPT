shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float coverage : hint_range(0.0,1.0) = 0.5;
uniform vec3 tint : source_color = vec3(0.98,0.96,0.91);
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world.xz*0.00028+vec2(TIME*0.001,0);
	float n=noise(p)*0.57+noise(p*2.1)*0.28+noise(p*4.3)*0.15;
	float alpha=smoothstep(0.64-coverage*0.27,0.79-coverage*0.24,n);
	ALBEDO=tint*mix(0.73,1.0,n);
	ALPHA=alpha*0.83;
}
