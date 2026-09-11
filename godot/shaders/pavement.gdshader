shader_type spatial;
uniform vec3 base_color : source_color = vec3(0.16,0.18,0.19);
uniform bool concrete = false;
uniform bool runway = false;
uniform vec3 threshold = vec3(0.0);
uniform vec3 inbound = vec3(-1.0,0.0,0.0);
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world.xz;
 float coarse=hash(floor(p/7.0));
 float grain=hash(floor(p*24.0));
 float fade=1.0-smoothstep(0.05,0.5,max(fwidth(p.x),fwidth(p.y)));
 vec3 tone=base_color*(0.94+coarse*0.12)+(grain-0.5)*0.025*fade;
 if(concrete){
  vec2 joints=abs(mod(p+3.0,6.0)-3.0);
  float line=1.0-smoothstep(0.012,0.035,min(joints.x,joints.y));
  float joint_fade=1.0-smoothstep(0.08,0.5,max(fwidth(p.x),fwidth(p.y)));
  tone*=1.0-line*0.32*joint_fade;
 }else{
  float seam=1.0-smoothstep(0.025,0.09,abs(mod(p.x+p.y*0.08,18.0)-9.0));
  tone*=1.0-seam*0.12*fade;
 }
 if(runway){
  vec3 rel=world-threshold;
  float along=dot(rel,inbound);
  float across=dot(rel,cross(inbound,vec3(0.0,1.0,0.0)));
  float rubber=(1.0-smoothstep(1.8,3.0,abs(abs(across)-2.2)))*smoothstep(120.0,300.0,along)*(1.0-smoothstep(600.0,1100.0,along));
  rubber*=0.5+0.5*hash(floor(vec2(across*8.0,along*0.1)));
  tone*=1.0-rubber*0.6;
 }
 ALBEDO=tone;
 ROUGHNESS=0.9;
 SPECULAR=0.2;
}
