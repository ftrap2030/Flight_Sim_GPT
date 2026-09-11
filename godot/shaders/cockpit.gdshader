shader_type spatial;
uniform vec3 panel_color : source_color = vec3(0.18,0.235,0.255);
varying vec3 local;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
void vertex(){local=VERTEX;}
void fragment(){
 float grain=hash(floor(local*1900.0));
 ALBEDO=panel_color*(0.95+grain*0.10);
 ROUGHNESS=0.76+grain*0.12;
 SPECULAR=0.25;
}
